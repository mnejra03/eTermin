using eTermin.Application.DTOs;
using eTermin.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace eTermin.Api.Controllers;

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
    public async Task<ActionResult<SalonDto>> CreateSalon(SalonDto salonDto)
    {
        var salon = await _salonService.CreateAsync(salonDto);

        return CreatedAtAction(
            nameof(GetSalon),
            new { id = salon.Id },
            salon);
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
    public async Task<IActionResult> UpdateSalon(int id, SalonDto salonDto)
    {
        var updated = await _salonService.UpdateAsync(id, salonDto);

        if (!updated)
        {
            return NotFound();
        }

        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteSalon(int id)
    {
        var deleted = await _salonService.DeleteAsync(id);

        if (!deleted)
        {
            return NotFound();
        }

        return NoContent();
    }
}