using eTermin.Api.DTOs;
using eTermin.Application.DTOs;
using eTermin.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eTermin.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class AppointmentsController : ControllerBase
{
    private readonly IAppointmentService _appointmentService;

    public AppointmentsController(IAppointmentService appointmentService)
    {
        _appointmentService = appointmentService;
    }

    [HttpGet]
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

        return Ok(appointment);
    }

    [HttpPost]
    public async Task<ActionResult<AppointmentDto>> CreateAppointment(
    AppointmentDto appointmentDto)
    {
        try
        {
            var userIdClaim = User.FindFirst(
                System.Security.Claims.ClaimTypes.NameIdentifier);

            if (userIdClaim == null)
                return Unauthorized();

            var userId = int.Parse(userIdClaim.Value);

            var isAdmin = User.IsInRole("Admin");

            if (!isAdmin)
            {
                appointmentDto.UserId = userId;
            }

            var appointment =
                await _appointmentService.CreateAsync(appointmentDto);

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
    public async Task<IActionResult> UpdateAppointment(
    int id,
    AppointmentDto appointmentDto)
    {
        try
        {
            var userIdClaim = User.FindFirst(
                System.Security.Claims.ClaimTypes.NameIdentifier);

            if (userIdClaim == null)
                return Unauthorized();

            var userId = int.Parse(userIdClaim.Value);

            var existingAppointment =
                await _appointmentService.GetByIdAsync(id);

            if (existingAppointment == null)
                return NotFound();

            var isAdmin = User.IsInRole("Admin");

            if (existingAppointment.UserId != userId && !isAdmin)
            {
                return Forbid();
            }

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

            var updated =
                await _appointmentService.UpdateAsync(
                    id,
                    appointmentDto);

            if (!updated)
                return NotFound();

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

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteAppointment(int id)
    {
        var deleted =
            await _appointmentService.DeleteAsync(id);

        if (!deleted)
            return NotFound();

        return NoContent();
    }

    [HttpGet("admin")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<List<AppointmentListDto>>> GetAllAppointmentsForAdmin()
    {
        var appointments =
            await _appointmentService.GetAllForListAsync();

        return Ok(appointments);
    }

    [HttpGet("dashboard")]
    [Authorize(Roles = "Admin")]
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
    [Authorize(Roles = "Admin")]
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