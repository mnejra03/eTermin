using System.Text.Json;
using eTermin.Application.DTOs;
using eTermin.Application.Services;
using RabbitMQ.Client;

namespace eTermin.Api.Services;

public sealed class RabbitMqAppointmentReminderPublisher : IAppointmentReminderPublisher
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<RabbitMqAppointmentReminderPublisher> _logger;

    public RabbitMqAppointmentReminderPublisher(
        IConfiguration configuration,
        ILogger<RabbitMqAppointmentReminderPublisher> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public Task PublishAsync(
        int appointmentId,
        CancellationToken cancellationToken = default)
    {
        if (!_configuration.GetValue<bool>("RabbitMQ:Enabled"))
            return Task.CompletedTask;

        var queue = _configuration["RabbitMQ:Queue"] ?? "appointment-reminders";

        try
        {
            var factory = new ConnectionFactory
            {
                HostName = _configuration["RabbitMQ:Host"] ?? "localhost",
                Port = _configuration.GetValue("RabbitMQ:Port", 5672),
                UserName = _configuration["RabbitMQ:Username"] ?? "guest",
                Password = _configuration["RabbitMQ:Password"] ?? "guest"
            };

            using var connection = factory.CreateConnection();
            using var channel = connection.CreateModel();
            DeclareQueues(channel, queue);

            var message = new AppointmentReminderMessage(appointmentId);
            var body = JsonSerializer.SerializeToUtf8Bytes(message);
            var properties = channel.CreateBasicProperties();
            properties.Persistent = true;
            properties.ContentType = "application/json";

            channel.BasicPublish(
                exchange: string.Empty,
                routingKey: queue,
                mandatory: false,
                basicProperties: properties,
                body: body);
        }
        catch (Exception exception)
        {
            _logger.LogError(
                exception,
                "Could not queue reminder update for appointment {AppointmentId}.",
                appointmentId);
        }

        return Task.CompletedTask;
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
