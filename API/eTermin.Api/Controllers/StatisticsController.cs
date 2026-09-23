using eTermin.Application.DTOs;
using eTermin.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eTermin.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize(Roles = "Admin")]
public class StatisticsController : ControllerBase
{
    private readonly IStatisticsService _statisticsService;

    public StatisticsController(
        IStatisticsService statisticsService)
    {
        _statisticsService = statisticsService;
    }

    [HttpGet("dashboard")]
    public async Task<ActionResult<DashboardStatisticsDto>>
    GetDashboardStatistics(
        DateTime? from,
        DateTime? to,
        int? salonId,
        string? status)
    {
        var statistics =
    await _statisticsService
        .GetDashboardStatisticsAsync(
            from,
            to,
            salonId,
            status);

        return Ok(statistics);
    }
}