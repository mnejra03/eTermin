using eTermin.Application.DTOs;
using eTermin.Application.Services;
using eTermin.Domain.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eTermin.Api.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class ServiceCategoriesController : ControllerBase
{
    private readonly IServiceCategoryService _categoryService;

    public ServiceCategoriesController(IServiceCategoryService categoryService)
    {
        _categoryService = categoryService;
    }

    [HttpGet]
    public async Task<ActionResult<List<ServiceCategoryDto>>> GetAll() =>
        Ok(await _categoryService.GetAllAsync());

    [HttpGet("{id}")]
    public async Task<ActionResult<ServiceCategoryDto>> GetById(int id)
    {
        var category = await _categoryService.GetByIdAsync(id);
        return category == null ? NotFound() : Ok(category);
    }

    [HttpPost]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<ActionResult<ServiceCategoryDto>> Create(
        ServiceCategoryDto categoryDto)
    {
        try
        {
            var category = await _categoryService.CreateAsync(categoryDto);
            return CreatedAtAction(
                nameof(GetById),
                new { id = category.Id },
                category);
        }
        catch (InvalidOperationException exception)
        {
            return Conflict(new { message = exception.Message });
        }
    }

    [HttpPut("{id}")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<IActionResult> Update(
        int id,
        ServiceCategoryDto categoryDto)
    {
        try
        {
            return await _categoryService.UpdateAsync(id, categoryDto)
                ? NoContent()
                : NotFound();
        }
        catch (InvalidOperationException exception)
        {
            return Conflict(new { message = exception.Message });
        }
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<IActionResult> Delete(int id)
    {
        try
        {
            return await _categoryService.DeleteAsync(id)
                ? NoContent()
                : NotFound();
        }
        catch (InvalidOperationException exception)
        {
            return Conflict(new { message = exception.Message });
        }
    }
}
