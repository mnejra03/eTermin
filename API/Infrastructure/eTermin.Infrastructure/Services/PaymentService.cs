using eTermin.Application.DTOs;
using eTermin.Application.Services;
using eTermin.Domain.Constants;
using eTermin.Domain.Entities;
using eTermin.Infrastructure.Data;
using eTermin.Domain.StateMachines;
using Microsoft.EntityFrameworkCore;

namespace eTermin.Infrastructure.Services;

public class PaymentService : IPaymentService
{
    private readonly eTerminDbContext _context;
    private readonly INotificationService _notificationService;
    private readonly IPayPalService _payPalService;

    public PaymentService(
    eTerminDbContext context,
    INotificationService notificationService,
    IPayPalService payPalService)
    {
        _context = context;
        _notificationService = notificationService;
        _payPalService = payPalService;
    }

    public async Task<PaymentDto?> GetByIdAsync(int id, int? userId = null)
    {
        var payment = await _context.Payments
            .Where(x => x.Id == id)
            .Where(x => userId == null || _context.Appointments.Any(a =>
                a.Id == x.AppointmentId && a.UserId == userId))
            .FirstOrDefaultAsync();

        if (payment == null)
            return null;

        return MapToDto(payment);
    }

    public async Task<List<PaymentDto>?> GetByAppointmentIdAsync(
        int appointmentId,
        int? userId = null)
    {
        var ownsAppointment = await _context.Appointments.AnyAsync(a =>
            a.Id == appointmentId && (userId == null || a.UserId == userId));

        if (!ownsAppointment)
            return null;

        var payments = await _context.Payments
            .Where(x => x.AppointmentId == appointmentId)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync();

        return payments
            .Select(MapToDto)
            .ToList();
    }

    public async Task<PaymentDto?> CreateAsync(
        PaymentDto paymentDto,
        int? userId = null)
    {
        var appointment = await _context.Appointments
            .FirstOrDefaultAsync(x =>
                x.Id == paymentDto.AppointmentId &&
                (userId == null || x.UserId == userId));

        if (appointment == null)
            return null;

        if (appointment.Status != AppointmentStatuses.Pending)
            throw new InvalidOperationException(
                appointment.Status == AppointmentStatuses.Cancelled
                    ? "Nije moguće platiti otkazani termin."
                    : "Nije moguće platiti termin koji nije na čekanju.");

        var existingPayments = await _context.Payments
            .Where(x => x.AppointmentId == appointment.Id)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync();

        if (existingPayments.Any(x => x.Status == PaymentStatuses.Completed))
            throw new InvalidOperationException(
                "Termin je već plaćen.");

        var existingPendingPayment = existingPayments
            .FirstOrDefault(x => x.Status == PaymentStatuses.Pending);

        if (existingPendingPayment != null)
            return MapToDto(existingPendingPayment);

        var payment = new Payment
        {
            AppointmentId = appointment.Id,
            Amount = appointment.Price,
            PaymentMethod = paymentDto.PaymentMethod,
            Status = PaymentStatuses.Pending,
            TransactionId = string.Empty,
            CreatedAt = DateTime.UtcNow
        };

        _context.Payments.Add(payment);

        await _context.SaveChangesAsync();

        return MapToDto(payment);
    }

    public async Task<PayPalOrderResult?> CreatePayPalOrderAsync(
        int paymentId,
        int? userId = null)
    {
        var payment = await _context.Payments
            .Where(x => x.Id == paymentId)
            .Where(x => userId == null || _context.Appointments.Any(a =>
                a.Id == x.AppointmentId && a.UserId == userId))
            .FirstOrDefaultAsync();

        if (payment == null)
            return null;

        if (payment.Status != PaymentStatuses.Pending)
            throw new InvalidOperationException(
                "PayPal nalog se može kreirati samo za uplatu na čekanju.");

        var appointment = await _context.Appointments
            .FirstAsync(x => x.Id == payment.AppointmentId);

        if (appointment.Status != AppointmentStatuses.Pending)
            throw new InvalidOperationException(
                appointment.Status == AppointmentStatuses.Cancelled
                    ? "Nije moguće kreirati PayPal nalog za otkazani termin."
                    : "Nije moguće platiti termin koji nije na čekanju.");

        var serviceName = await _context.Services
            .Where(x => x.Id == appointment.ServiceId)
            .Select(x => x.Name)
            .FirstOrDefaultAsync() ?? "Usluga";
        var salonName = await _context.Salons
            .Where(x => x.Id == appointment.SalonId)
            .Select(x => x.Name)
            .FirstOrDefaultAsync() ?? "Salon";

        var order = await _payPalService.CreateOrderAsync(
            payment.Amount,
            "BAM",
            $"{serviceName} - {salonName}");

        payment.PayPalOrderId = order.OrderId;
        await _context.SaveChangesAsync();

        return order;
    }

    public async Task<string?> CapturePayPalOrderAsync(
        int paymentId,
        int? userId = null)
    {
        var payment = await _context.Payments
            .Where(x => x.Id == paymentId)
            .Where(x => userId == null || _context.Appointments.Any(a =>
                a.Id == x.AppointmentId && a.UserId == userId))
            .FirstOrDefaultAsync();

        if (payment == null)
            return null;

        var appointment = await _context.Appointments
            .FirstAsync(x => x.Id == payment.AppointmentId);

        if (appointment.Status == AppointmentStatuses.Cancelled)
            throw new InvalidOperationException(
                "Termin je otkazan; naplata nije pokrenuta.");

        if (payment.Status == PaymentStatuses.Completed)
            return payment.TransactionId;

        if (!AppointmentStateMachine.CanTransition(
                appointment.Status,
                AppointmentStatuses.Confirmed) ||
            appointment.Status != AppointmentStatuses.Pending)
            throw new InvalidOperationException(
                "Termin više nije na čekanju; naplata nije pokrenuta.");

        if (string.IsNullOrWhiteSpace(payment.PayPalOrderId))
            throw new InvalidOperationException(
                "Za ovu uplatu nije kreiran PayPal nalog.");

        if (payment.Status != PaymentStatuses.Pending)
            throw new InvalidOperationException(
                "Samo uplata na čekanju može biti naplaćena.");

        var captureId = await _payPalService.CaptureOrderAsync(
            payment.PayPalOrderId);

        var updated = await UpdateStatusAsync(
            paymentId,
            PaymentStatuses.Completed,
            captureId,
            userId);

        return updated ? captureId : null;
    }

    public async Task<bool> UpdateStatusAsync(
    int id,
    string status,
    string? transactionId = null,
    int? userId = null)
    {
        var payment = await _context.Payments
            .Where(x => x.Id == id)
            .Where(x => userId == null || _context.Appointments.Any(a =>
                a.Id == x.AppointmentId && a.UserId == userId))
            .FirstOrDefaultAsync();

        if (payment == null)
            return false;

        if (payment.Status == PaymentStatuses.Completed)
            return true;

        if (status == PaymentStatuses.Completed &&
            string.IsNullOrWhiteSpace(transactionId))
        {
            throw new InvalidOperationException(
                "Uplata se može označiti završenom samo nakon PayPal potvrde.");
        }

        if (status == PaymentStatuses.Completed)
        {
            var appointment = await _context.Appointments
                .FirstOrDefaultAsync(x =>
                    x.Id == payment.AppointmentId);

            if (appointment == null)
                throw new InvalidOperationException("Termin uplate nije pronađen.");

            if (appointment.Status == AppointmentStatuses.Cancelled)
                throw new InvalidOperationException(
                    "Termin je otkazan; uplata se ne može potvrditi.");

            if (!AppointmentStateMachine.CanTransition(
                    appointment.Status,
                    AppointmentStatuses.Confirmed))
                throw new InvalidOperationException(
                    $"Nije dozvoljen prelaz statusa termina '{appointment.Status}' u '{AppointmentStatuses.Confirmed}'.");

            var previousStatus = appointment.Status;
            payment.Status = PaymentStatuses.Completed;
            payment.TransactionId = transactionId!;
            appointment.Status = AppointmentStatuses.Confirmed;
            _context.AppointmentStatusHistories.Add(
                new AppointmentStatusHistory
                {
                    AppointmentId = appointment.Id,
                    PreviousStatus = previousStatus,
                    NewStatus = appointment.Status,
                    ChangedByUserId = userId ?? appointment.UserId,
                    ChangedAt = DateTime.UtcNow
                });

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
        else
        {
            payment.Status = status;
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
