using eTermin.Application.DTOs;
using eTermin.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using eTermin.Domain.Constants;
using eTermin.Api.QueryParameters;

namespace eTermin.Api.Controllers;

[Authorize(Roles = UserRoles.Admin)]
[Route("api/[controller]")]
[ApiController]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;

    public UsersController(IUserService userService)
    {
        _userService = userService;
    }

    [HttpGet]
    public async Task<ActionResult<PagedResult<UserDto>>> GetUsers(
        int page = 1,
        int pageSize = PaginationOptions.DefaultPageSize)
    {
        (page, pageSize) = PaginationOptions.Normalize(page, pageSize);
        var users = await _userService.GetAllAsync(page, pageSize);

        return Ok(users);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<UserDto>> GetUser(int id)
    {
        var user = await _userService.GetByIdAsync(id);

        if (user == null)
            return NotFound();

        return Ok(user);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateUser(
        int id,
        UserDto userDto)
    {
        var updated =
            await _userService.UpdateAsync(id, userDto);

        if (!updated)
            return NotFound();

        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteUser(int id)
    {
        var deleted = await _userService.DeleteAsync(id);

        if (!deleted)
            return NotFound();

        return NoContent();
    }
}
