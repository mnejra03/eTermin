using eTermin.Application.DTOs;

namespace eTermin.Application.Services;

public interface IStatisticsService
{
    Task<DashboardStatisticsDto> GetDashboardStatisticsAsync(
        DateTime? from,
        DateTime? to,
        int? salonId);
}