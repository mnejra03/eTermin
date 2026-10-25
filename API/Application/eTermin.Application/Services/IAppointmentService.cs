using eTermin.Api.DTOs;
using eTermin.Application.DTOs;

namespace eTermin.Application.Services;

public interface IAppointmentService
{
    Task<List<AppointmentDto>> GetAllAsync();

    Task<AppointmentDto?> GetByIdAsync(int id);

    Task<AppointmentDto> CreateAsync(AppointmentDto appointmentDto, int actorUserId);

    Task<bool> UpdateAsync(int id, AppointmentDto appointmentDto, int actorUserId);

    Task<bool> CancelAsync(int id, int actorUserId, string reason, bool isAdmin);

    Task<List<AppointmentStatusHistoryDto>> GetStatusHistoryAsync(
        int appointmentId);

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
