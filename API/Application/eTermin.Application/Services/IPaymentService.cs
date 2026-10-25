using eTermin.Application.DTOs;

namespace eTermin.Application.Services;

public interface IPaymentService
{
    Task<PaymentDto?> GetByIdAsync(int id, int? userId = null);

    Task<List<PaymentDto>?> GetByAppointmentIdAsync(
        int appointmentId,
        int? userId = null);

    Task<PaymentDto?> CreateAsync(PaymentDto paymentDto, int? userId = null);

    Task<PayPalOrderResult?> CreatePayPalOrderAsync(
        int paymentId,
        int? userId = null);

    Task<string?> CapturePayPalOrderAsync(
        int paymentId,
        int? userId = null);

    Task<bool> UpdateStatusAsync(
    int id,
    string status,
    string? transactionId = null,
    int? userId = null);
}
