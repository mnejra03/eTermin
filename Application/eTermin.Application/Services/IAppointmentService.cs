using eTermin.Application.DTOs;

namespace eTermin.Application.Services;

public interface IAppointmentService
{
    Task<List<AppointmentDto>> GetAllAsync();

    Task<AppointmentDto?> GetByIdAsync(int id);

    Task<AppointmentDto> CreateAsync(AppointmentDto appointmentDto);

    Task<bool> UpdateAsync(int id, AppointmentDto appointmentDto);

    Task<bool> DeleteAsync(int id);
}