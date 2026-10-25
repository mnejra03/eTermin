using eTermin.Application.DTOs;
using eTermin.Application.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

using eTermin.Domain.Constants;

namespace eTermin.Api.Controllers;

[Authorize]
[Route("api/[controller]")]
[ApiController]
public class ServicesController : ControllerBase
{
    private readonly IServiceService _serviceService;

    public ServicesController(IServiceService serviceService)
    {
        _serviceService = serviceService;
    }

    [HttpGet]
    public async Task<ActionResult<List<ServiceDto>>> GetServices()
    {
        var services = await _serviceService.GetAllAsync();

        return Ok(services);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ServiceDto>> GetService(int id)
    {
        var service = await _serviceService.GetByIdAsync(id);

        if (service == null)
        {
            return NotFound();
        }

        return Ok(service);
    }

    [HttpPost]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<ActionResult<ServiceDto>> CreateService(
        ServiceDto serviceDto)
    {
        try
        {
            var service = await _serviceService.CreateAsync(serviceDto);

            return CreatedAtAction(
                nameof(GetService),
                new { id = service.Id },
                service);
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
    }

    [HttpPut("{id}")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<IActionResult> UpdateService(
        int id,
        ServiceDto serviceDto)
    {
        bool updated;
        try
        {
            updated = await _serviceService.UpdateAsync(id, serviceDto);
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
    public async Task<IActionResult> DeleteService(int id)
    {
        try
        {
            var deleted =
                await _serviceService.DeleteAsync(id);

            if (!deleted)
            {
                return NotFound();
            }

            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new
            {
                message = ex.Message
            });
        }
    }
}
