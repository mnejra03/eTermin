using eTermin.Api.DTOs;
using eTermin.Application.DTOs;

namespace eTermin.Application.Services;

public interface IAppointmentService
{
    Task<List<AppointmentDto>> GetAllAsync();

    Task<AppointmentDto?> GetByIdAsync(int id);

    Task<AppointmentDto> CreateAsync(AppointmentDto appointmentDto);

    Task<bool> UpdateAsync(int id, AppointmentDto appointmentDto);

    Task<bool> DeleteAsync(int id);

    Task<List<AvailableSlotDto>> GetAvailableSlotsAsync(
    int salonId,
    int employeeId,
    int serviceId,
    DateTime date);

    Task<List<DashboardAppointmentDto>> GetDashboardAppointmentsAsync(
    DateTime date,
    int? salonId);

    Task<List<AppointmentListDto>> GetAllForListAsync();

    Task<List<AppointmentListDto>> GetMyForListAsync(int userId);

    Task<DashboardAvailableSlotsDto> GetDashboardAvailableSlotsAsync(
    DateTime date,
    int? salonId);
}