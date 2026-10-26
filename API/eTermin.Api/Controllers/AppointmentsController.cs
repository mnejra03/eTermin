using eTermin.Api.DTOs;
using eTermin.Application.DTOs;
using eTermin.Application.Services;
using eTermin.Domain.Constants;
using eTermin.Api.QueryParameters;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace eTermin.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class AppointmentsController : ControllerBase
{
    private readonly IAppointmentService _appointmentService;
    private readonly IAppointmentReminderPublisher _reminderPublisher;

    public AppointmentsController(
        IAppointmentService appointmentService,
        IAppointmentReminderPublisher reminderPublisher)
    {
        _appointmentService = appointmentService;
        _reminderPublisher = reminderPublisher;
    }

    [HttpGet]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<ActionResult<PagedResult<AppointmentDto>>> GetAppointments(
        int page = 1,
        int pageSize = PaginationOptions.DefaultPageSize)
    {
        (page, pageSize) = PaginationOptions.Normalize(page, pageSize);
        var appointments = await _appointmentService.GetAllAsync(page, pageSize);

        return Ok(appointments);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<AppointmentDto>> GetAppointment(int id)
    {
        var appointment = await _appointmentService.GetByIdAsync(id);

        if (appointment == null)
            return NotFound();

        if (!User.IsInRole(UserRoles.Admin))
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (userIdClaim == null ||
                !int.TryParse(userIdClaim.Value, out var userId))
            {
                return Unauthorized();
            }

            if (appointment.UserId != userId)
                return NotFound();
        }

        return Ok(appointment);
    }

    [HttpPost]
    public async Task<ActionResult<AppointmentDto>> CreateAppointment(
    CreateAppointmentDto createAppointmentDto)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null ||
            !int.TryParse(userIdClaim.Value, out var currentUserId))
        {
            return Unauthorized();
        }

        var targetUserId = currentUserId;
        if (User.IsInRole(UserRoles.Admin))
        {
            if (createAppointmentDto.UserId is not > 0)
            {
                return BadRequest(new
                {
                    message = "Administrator mora odabrati korisnika termina."
                });
            }

            targetUserId = createAppointmentDto.UserId.Value;
        }

        var appointmentDto = new AppointmentDto
        {
            UserId = targetUserId,
            SalonId = createAppointmentDto.SalonId,
            EmployeeId = createAppointmentDto.EmployeeId,
            ServiceId = createAppointmentDto.ServiceId,
            StartTime = createAppointmentDto.StartTime,
            EndTime = createAppointmentDto.EndTime,
            Status = AppointmentStatuses.Pending,
            Price = createAppointmentDto.Price
        };

        var appointment = await _appointmentService.CreateAsync(
            appointmentDto,
            currentUserId);

        await _reminderPublisher.PublishAsync(appointment.Id);

        return CreatedAtAction(
            nameof(GetAppointment),
            new { id = appointment.Id },
            appointment);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<IActionResult> UpdateAppointment(
    int id,
    AppointmentDto appointmentDto)
    {
        var existingAppointment =
            await _appointmentService.GetByIdAsync(id);

        if (existingAppointment == null)
            return NotFound();

            // Korisnik ne može mijenjati vlasnika termina.
            appointmentDto.UserId = existingAppointment.UserId;

            // Admin može mijenjati:
            // SalonId
            // EmployeeId
            // ServiceId
            // StartTime
            // EndTime
            // Status
            // Price

        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null ||
            !int.TryParse(userIdClaim.Value, out var actorUserId))
            return Unauthorized();

        var updated = await _appointmentService.UpdateAsync(
            id,
            appointmentDto,
            actorUserId);

        if (!updated)
            return NotFound();

        await _reminderPublisher.PublishAsync(id);

        return NoContent();
    }

    [HttpGet("{id}/status-history")]
    public async Task<ActionResult<List<AppointmentStatusHistoryDto>>>
        GetStatusHistory(int id)
    {
        var appointment = await _appointmentService.GetByIdAsync(id);
        if (appointment == null)
            return NotFound();

        if (!User.IsInRole(UserRoles.Admin))
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            if (userIdClaim == null ||
                !int.TryParse(userIdClaim.Value, out var userId))
                return Unauthorized();

            if (appointment.UserId != userId)
                return NotFound();
        }

        return Ok(await _appointmentService.GetStatusHistoryAsync(id));
    }

    [HttpPut("{id}/cancel")]
    public async Task<IActionResult> CancelAppointment(
        int id,
        [FromBody] CancelAppointmentRequest request)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null ||
            !int.TryParse(userIdClaim.Value, out var userId))
        {
            return Unauthorized();
        }

        if (string.IsNullOrWhiteSpace(request.Reason))
            return BadRequest(new { message = "Unesite razlog otkazivanja." });

        if (request.Reason.Trim().Length > 500)
            return BadRequest(new { message = "Razlog može imati najviše 500 znakova." });

        var cancelled = await _appointmentService.CancelAsync(
            id,
            userId,
            request.Reason,
            User.IsInRole(UserRoles.Admin));
        if (!cancelled)
            return NotFound();

        return NoContent();
    }

    [HttpGet("admin")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<ActionResult<PagedResult<AppointmentListDto>>> GetAllAppointmentsForAdmin(
        int page = 1,
        int pageSize = PaginationOptions.DefaultPageSize,
        DateTime? from = null,
        DateTime? to = null,
        int? salonId = null,
        string? status = null,
        string? search = null)
    {
        (page, pageSize) = PaginationOptions.Normalize(page, pageSize);
        var appointments =
            await _appointmentService.GetAllForListAsync(
                page, pageSize, from, to, salonId, status, search);

        return Ok(appointments);
    }

    [HttpGet("dashboard")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<ActionResult<List<DashboardAppointmentDto>>>
    GetDashboardAppointments(int? salonId)
    {
        var appointments =
            await _appointmentService.GetDashboardAppointmentsAsync(
                DateTime.Today,
                salonId);

        return Ok(appointments);
    }

    [HttpGet("my")]
    public async Task<ActionResult<PagedResult<AppointmentListDto>>> GetMyAppointments(
        int page = 1,
        int pageSize = PaginationOptions.DefaultPageSize,
        string? status = null)
    {
        var userIdClaim = User.FindFirst(
            System.Security.Claims.ClaimTypes.NameIdentifier);

        if (userIdClaim == null)
            return Unauthorized();

        var userId = int.Parse(userIdClaim.Value);
        (page, pageSize) = PaginationOptions.Normalize(page, pageSize);

        var appointments =
            await _appointmentService.GetMyForListAsync(
                userId,
                page,
                pageSize,
                status);

        return Ok(appointments);
    }

    [HttpGet("available-slots")]
    [Authorize]
    public async Task<ActionResult<List<AvailableSlotDto>>> GetAvailableSlots(
    int salonId,
    int employeeId,
    int serviceId,
    DateTime date)
    {
        var slots = await _appointmentService.GetAvailableSlotsAsync(
            salonId,
            employeeId,
            serviceId,
            date);

        return Ok(slots);
    }

    [HttpGet("dashboard-available-slots")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<ActionResult<DashboardAvailableSlotsDto>>
     GetDashboardAvailableSlots(int? salonId)
    {
        var result = await _appointmentService.GetDashboardAvailableSlotsAsync(
            DateTime.Today,
            salonId);

        return Ok(result);
    }
}

public class CancelAppointmentRequest
{
    public string Reason { get; set; } = string.Empty;
}
