using eTermin.Application.DTOs;
using eTermin.Application.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;

using eTermin.Domain.Constants;
using eTermin.Api.QueryParameters;

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
    public async Task<ActionResult<PagedResult<ServiceDto>>> GetServices(
        int page = 1,
        int pageSize = PaginationOptions.DefaultPageSize)
    {
        (page, pageSize) = PaginationOptions.Normalize(page, pageSize);
        var services = await _serviceService.GetAllAsync(page, pageSize);

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
        var service = await _serviceService.CreateAsync(serviceDto);
        return CreatedAtAction(
            nameof(GetService),
            new { id = service.Id },
            service);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<IActionResult> UpdateService(
        int id,
        ServiceDto serviceDto)
    {
        var updated = await _serviceService.UpdateAsync(id, serviceDto);

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
        var deleted = await _serviceService.DeleteAsync(id);

        if (!deleted)
            return NotFound();

        return NoContent();
    }
}
