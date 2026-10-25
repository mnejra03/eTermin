using eTermin.Api.DTOs;
using eTermin.Application.DTOs;

namespace eTermin.Application.Services;

public interface IAppointmentService
{
    Task<PagedResult<AppointmentDto>> GetAllAsync(int page, int pageSize);

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

    Task<PagedResult<AppointmentListDto>> GetAllForListAsync(
        int page,
        int pageSize);

    Task<PagedResult<AppointmentListDto>> GetMyForListAsync(
        int userId,
        int page,
        int pageSize,
        string? status);

    Task<DashboardAvailableSlotsDto> GetDashboardAvailableSlotsAsync(
    DateTime date,
    int? salonId);
}
