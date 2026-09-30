using eTermin.Application.DTOs;
using eTermin.Application.Services;
using eTermin.Domain.Entities;
using eTermin.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace eTermin.Infrastructure.Services;

public class PaymentService : IPaymentService
{
    private readonly eTerminDbContext _context;
    private readonly INotificationService _notificationService;

    public PaymentService(
    eTerminDbContext context,
    INotificationService notificationService)
    {
        _context = context;
        _notificationService = notificationService;
    }

    public async Task<PaymentDto?> GetByIdAsync(int id)
    {
        var payment = await _context.Payments
            .FirstOrDefaultAsync(x => x.Id == id);

        if (payment == null)
            return null;

        return MapToDto(payment);
    }

    public async Task<List<PaymentDto>> GetByAppointmentIdAsync(
        int appointmentId)
    {
        var payments = await _context.Payments
            .Where(x => x.AppointmentId == appointmentId)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync();

        return payments
            .Select(MapToDto)
            .ToList();
    }

    public async Task<PaymentDto> CreateAsync(
        PaymentDto paymentDto)
    {
        var appointment = await _context.Appointments
            .FirstOrDefaultAsync(x =>
                x.Id == paymentDto.AppointmentId);

        if (appointment == null)
            throw new Exception("Termin ne postoji.");

        if (appointment.Status == "Cancelled")
            throw new Exception(
                "Nije moguće platiti otkazani termin.");

        var payment = new Payment
        {
            AppointmentId = appointment.Id,
            Amount = appointment.Price,
            PaymentMethod = paymentDto.PaymentMethod,
            Status = "Pending",
            TransactionId = string.Empty,
            CreatedAt = DateTime.UtcNow
        };

        _context.Payments.Add(payment);

        await _context.SaveChangesAsync();

        return MapToDto(payment);
    }

    public async Task<bool> UpdateStatusAsync(
    int id,
    string status,
    string? transactionId = null)
    {
        var payment = await _context.Payments
            .FirstOrDefaultAsync(x => x.Id == id);

        if (payment == null)
            return false;

        if (payment.Status == "Completed")
            return true;

        payment.Status = status;

        if (status == "Completed")
        {
            payment.TransactionId =
                transactionId ?? $"PAY-{Guid.NewGuid():N}";

            var appointment = await _context.Appointments
                .FirstOrDefaultAsync(x =>
                    x.Id == payment.AppointmentId);

            if (appointment != null)
            {
                appointment.Status = "Confirmed";

                await _notificationService.CreateAsync(
                    new NotificationDto
                    {
                        UserId = appointment.UserId,
                        AppointmentId = appointment.Id,
                        Title = "Plaćanje uspješno",
                        Message =
                            $"Vaše PayPal plaćanje u iznosu od " +
                            $"{payment.Amount:0.00} KM je uspješno izvršeno. " +
                            "Termin je potvrđen.",
                        IsRead = false
                    });
            }
        }

        await _context.SaveChangesAsync();

        return true;
    }

    private static PaymentDto MapToDto(Payment payment)
    {
        return new PaymentDto
        {
            Id = payment.Id,
            AppointmentId = payment.AppointmentId,
            Amount = payment.Amount,
            PaymentMethod = payment.PaymentMethod,
            Status = payment.Status,
            TransactionId = payment.TransactionId,
            CreatedAt = payment.CreatedAt
        };
    }
}