using eTermin.Application.DTOs;
using eTermin.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace eTermin.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
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
}