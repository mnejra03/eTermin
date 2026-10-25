using eTermin.Application.DTOs;
using eTermin.Application.Services;
using eTermin.Domain.Constants;
using eTermin.Api.QueryParameters;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eTermin.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class CitiesController : ControllerBase
{
    private readonly ICityService _cityService;

    public CitiesController(ICityService cityService)
    {
        _cityService = cityService;
    }

    [HttpGet]
    public async Task<ActionResult<PagedResult<CityDto>>> GetAll(
        int page = 1,
        int pageSize = PaginationOptions.DefaultPageSize)
    {
        (page, pageSize) = PaginationOptions.Normalize(page, pageSize);
        return Ok(await _cityService.GetAllAsync(page, pageSize));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<CityDto>> GetById(int id)
    {
        var city = await _cityService.GetByIdAsync(id);
        return city == null ? NotFound() : Ok(city);
    }

    [HttpPost]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<ActionResult<CityDto>> Create(CityDto cityDto)
    {
        var city = await _cityService.CreateAsync(cityDto);
        return CreatedAtAction(nameof(GetById), new { id = city.Id }, city);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<IActionResult> Update(int id, CityDto cityDto) =>
        await _cityService.UpdateAsync(id, cityDto)
            ? NoContent()
            : NotFound();

    [HttpDelete("{id}")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<IActionResult> Delete(int id) =>
        await _cityService.DeleteAsync(id) ? NoContent() : NotFound();
}
