using eTermin.Api.DTOs;
using eTermin.Application.DTOs;
using eTermin.Application.Services;
using eTermin.Domain.Constants;
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
    public async Task<ActionResult<List<AppointmentDto>>> GetAppointments()
    {
        var appointments = await _appointmentService.GetAllAsync();

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
        try
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

            var appointment =
                await _appointmentService.CreateAsync(
                    appointmentDto,
                    currentUserId);

            await _reminderPublisher.PublishAsync(appointment.Id);

            return CreatedAtAction(
                nameof(GetAppointment),
                new { id = appointment.Id },
                appointment);
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                message = ex.Message
            });
        }
    }

    [HttpPut("{id}")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<IActionResult> UpdateAppointment(
    int id,
    AppointmentDto appointmentDto)
    {
        try
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

            var updated =
                await _appointmentService.UpdateAsync(
                    id,
                    appointmentDto,
                    actorUserId);

            if (!updated)
                return NotFound();

            await _reminderPublisher.PublishAsync(id);

            return NoContent();
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                message = ex.Message
            });
        }
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

        try
        {
            var cancelled = await _appointmentService.CancelAsync(
                id,
                userId,
                request.Reason,
                User.IsInRole(UserRoles.Admin));
            if (!cancelled)
                return NotFound();

            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    [HttpGet("admin")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<ActionResult<List<AppointmentListDto>>> GetAllAppointmentsForAdmin()
    {
        var appointments =
            await _appointmentService.GetAllForListAsync();

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
    public async Task<ActionResult<List<AppointmentListDto>>> GetMyAppointments()
    {
        var userIdClaim = User.FindFirst(
            System.Security.Claims.ClaimTypes.NameIdentifier);

        if (userIdClaim == null)
            return Unauthorized();

        var userId = int.Parse(userIdClaim.Value);

        var appointments =
            await _appointmentService.GetMyForListAsync(userId);

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
        try
        {
            var slots = await _appointmentService.GetAvailableSlotsAsync(
                salonId,
                employeeId,
                serviceId,
                date);

            return Ok(slots);
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                message = ex.Message
            });
        }
    }

    [HttpGet("dashboard-available-slots")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<ActionResult<DashboardAvailableSlotsDto>>
     GetDashboardAvailableSlots(int? salonId)
    {
        try
        {
            var result =
                await _appointmentService.GetDashboardAvailableSlotsAsync(
                    DateTime.Today,
                    salonId);

            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                message = ex.Message
            });
        }
    }
}

public class CancelAppointmentRequest
{
    public string Reason { get; set; } = string.Empty;
}
