using System.Text.Json;
using eTermin.Application.DTOs;
using eTermin.Domain.Constants;
using eTermin.Domain.Entities;
using eTermin.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace eTermin.Worker;

public sealed class Worker : BackgroundService
{
    private const string ReminderType = "AppointmentReminder";

    private readonly IServiceScopeFactory _scopeFactory;
    private readonly IConfiguration _configuration;
    private readonly ILogger<Worker> _logger;

    public Worker(
        IServiceScopeFactory scopeFactory,
        IConfiguration configuration,
        ILogger<Worker> logger)
    {
        _scopeFactory = scopeFactory;
        _configuration = configuration;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (!_configuration.GetValue<bool>("RabbitMQ:Enabled"))
        {
            _logger.LogWarning("RabbitMQ reminder consumer is disabled.");
            return;
        }

        var queue = _configuration["RabbitMQ:Queue"] ?? "appointment-reminders";
        var factory = new ConnectionFactory
        {
            HostName = _configuration["RabbitMQ:Host"] ?? "localhost",
            Port = _configuration.GetValue("RabbitMQ:Port", 5672),
            UserName = _configuration["RabbitMQ:Username"] ?? "guest",
            Password = _configuration["RabbitMQ:Password"] ?? "guest",
            DispatchConsumersAsync = true,
            AutomaticRecoveryEnabled = true,
            NetworkRecoveryInterval = TimeSpan.FromSeconds(5)
        };

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var connection = factory.CreateConnection("etermin-reminder-worker");
                using var channel = connection.CreateModel();
                DeclareQueues(channel, queue);
                channel.BasicQos(prefetchSize: 0, prefetchCount: 1, global: false);
                await ScheduleUpcomingRemindersAsync(stoppingToken);

                var consumer = new AsyncEventingBasicConsumer(channel);
                consumer.Received += async (_, eventArgs) =>
                {
                    try
                    {
                        var message = JsonSerializer.Deserialize<AppointmentReminderMessage>(
                            eventArgs.Body.ToArray());
                        if (message == null || message.AppointmentId <= 0)
                            throw new InvalidDataException("Invalid appointment reminder message.");

                        await ScheduleReminderAsync(message.AppointmentId, stoppingToken);
                        channel.BasicAck(eventArgs.DeliveryTag, multiple: false);
                    }
                    catch (Exception exception)
                    {
                        _logger.LogError(exception, "Failed to process an appointment reminder message.");
                        channel.BasicNack(
                            eventArgs.DeliveryTag,
                            multiple: false,
                            requeue: false);
                    }
                };

                channel.BasicConsume(
                    queue: queue,
                    autoAck: false,
                    consumer: consumer);

                _logger.LogInformation("Consuming appointment reminder messages from {Queue}.", queue);
                using var timer = new PeriodicTimer(TimeSpan.FromMinutes(1));
                while (await timer.WaitForNextTickAsync(stoppingToken))
                    await ScheduleUpcomingRemindersAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception exception)
            {
                _logger.LogError(exception, "Reminder worker connection failed; retrying in five seconds.");
                try
                {
                    await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
                }
                catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
                {
                    break;
                }
            }
        }
    }

    private async Task ScheduleUpcomingRemindersAsync(CancellationToken cancellationToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<eTerminDbContext>();
        var appointmentIds = await context.Appointments
            .Where(appointment =>
                appointment.Status == AppointmentStatuses.Confirmed &&
                appointment.StartTime > DateTime.Now)
            .Select(appointment => appointment.Id)
            .ToListAsync(cancellationToken);

        foreach (var appointmentId in appointmentIds)
            await ScheduleReminderAsync(appointmentId, cancellationToken);

        _logger.LogInformation(
            "Checked {AppointmentCount} upcoming appointments for reminders.",
            appointmentIds.Count);
    }

    private async Task ScheduleReminderAsync(int appointmentId, CancellationToken cancellationToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<eTerminDbContext>();
        var reminder = await context.Notifications.FirstOrDefaultAsync(
            notification =>
                notification.AppointmentId == appointmentId &&
                notification.Type == ReminderType,
            cancellationToken);

        var appointment = await context.Appointments.FirstOrDefaultAsync(
            item => item.Id == appointmentId,
            cancellationToken);

        if (appointment == null ||
            appointment.Status != AppointmentStatuses.Confirmed ||
            appointment.StartTime <= DateTime.Now)
        {
            if (reminder != null && reminder.CreatedAt > DateTime.UtcNow)
            {
                context.Notifications.Remove(reminder);
                await context.SaveChangesAsync(cancellationToken);
            }
            return;
        }

        var leadHours = Math.Clamp(
            _configuration.GetValue("Reminder:LeadHours", 24),
            1,
            720);
        var startUtc = DateTime.SpecifyKind(
            appointment.StartTime,
            DateTimeKind.Local).ToUniversalTime();
        var scheduledForUtc = startUtc.AddHours(-leadHours);
        if (scheduledForUtc < DateTime.UtcNow)
            scheduledForUtc = DateTime.UtcNow;

        var salonName = await context.Salons
            .Where(salon => salon.Id == appointment.SalonId)
            .Select(salon => salon.Name)
            .FirstOrDefaultAsync(cancellationToken) ?? "odabrani salon";
        var serviceName = await context.Services
            .Where(service => service.Id == appointment.ServiceId)
            .Select(service => service.Name)
            .FirstOrDefaultAsync(cancellationToken) ?? "odabrana usluga";

        if (reminder == null)
        {
            reminder = new Notification
            {
                UserId = appointment.UserId,
                AppointmentId = appointment.Id,
                Type = ReminderType,
                IsRead = false
            };
            context.Notifications.Add(reminder);
        }

        reminder.UserId = appointment.UserId;
        reminder.CreatedAt = scheduledForUtc;
        reminder.Title = "Podsjetnik za termin";
        reminder.Message = $"Termin za uslugu {serviceName} u salonu {salonName} počinje {appointment.StartTime:dd.MM.yyyy. HH:mm}.";

        await context.SaveChangesAsync(cancellationToken);
        _logger.LogInformation(
            "Scheduled a reminder for appointment {AppointmentId} at {ScheduledForUtc} UTC.",
            appointmentId,
            scheduledForUtc);
    }

    private static void DeclareQueues(IModel channel, string queue)
    {
        channel.QueueDeclare(
            queue: queue + ".dead",
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: null);

        var arguments = new Dictionary<string, object>
        {
            ["x-dead-letter-exchange"] = string.Empty,
            ["x-dead-letter-routing-key"] = queue + ".dead"
        };

        channel.QueueDeclare(
            queue: queue,
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: arguments);
    }
}
