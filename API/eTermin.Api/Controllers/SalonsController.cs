using eTermin.Application.DTOs;
using eTermin.Application.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

using eTermin.Domain.Constants;

namespace eTermin.Api.Controllers;

[Authorize]
[Route("api/[controller]")]
[ApiController]
public class SalonsController : ControllerBase
{
    private readonly ISalonService _salonService;

    public SalonsController(ISalonService salonService)
    {
        _salonService = salonService;
    }

    [HttpGet]
    public async Task<ActionResult<List<SalonDto>>> GetSalons()
    {
        var salons = await _salonService.GetAllAsync();

        return Ok(salons);
    }

    [HttpPost]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<ActionResult<SalonDto>> CreateSalon(SalonDto salonDto)
    {
        try
        {
            var salon = await _salonService.CreateAsync(salonDto);

            return CreatedAtAction(
                nameof(GetSalon),
                new { id = salon.Id },
                salon);
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<SalonDto>> GetSalon(int id)
    {
        var salon = await _salonService.GetByIdAsync(id);

        if (salon == null)
        {
            return NotFound();
        }

        return Ok(salon);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<IActionResult> UpdateSalon(int id, SalonDto salonDto)
    {
        bool updated;
        try
        {
            updated = await _salonService.UpdateAsync(id, salonDto);
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }

        if (!updated)
        {
            return NotFound();
        }

        return NoContent();
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<IActionResult> DeleteSalon(int id)
    {
        bool deleted;
        try
        {
            deleted = await _salonService.DeleteAsync(id);
        }
        catch (InvalidOperationException exception)
        {
            return Conflict(new { message = exception.Message });
        }

        if (!deleted)
        {
            return NotFound();
        }

        return NoContent();
    }
}
