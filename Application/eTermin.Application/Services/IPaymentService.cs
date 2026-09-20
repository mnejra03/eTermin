using eTermin.Application.DTOs;

namespace eTermin.Application.Services;

public interface IPaymentService
{
    Task<PaymentDto?> GetByIdAsync(int id);

    Task<List<PaymentDto>> GetByAppointmentIdAsync(
        int appointmentId);

    Task<PaymentDto> CreateAsync(PaymentDto paymentDto);

    Task<bool> UpdateStatusAsync(
        int id,
        string status);
}