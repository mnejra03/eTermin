using eTermin.Application.DTOs;
using eTermin.Application.Services;
using Microsoft.AspNetCore.Mvc;

using Microsoft.AspNetCore.Authorization;
namespace eTermin.Api.Controllers;

[Authorize]
[Route("api/[controller]")]
[ApiController]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;

    public UsersController(IUserService userService)
    {
        _userService = userService;
    }

    [HttpGet("admin")]
    [Authorize(Roles = "Admin")]
    public IActionResult AdminTest()
    {
        return Ok(new
        {
            message = "Pristup administratora je uspješan."
        });
    }

    [HttpGet]
    public async Task<ActionResult<List<UserDto>>> GetUsers()
    {
        var users = await _userService.GetAllAsync();

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

    [HttpPost]
    public async Task<ActionResult<UserDto>> CreateUser(
        UserDto userDto)
    {
        var user = await _userService.CreateAsync(userDto);

        return CreatedAtAction(
            nameof(GetUser),
            new { id = user.Id },
            user);
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
        var deleted =
            await _userService.DeleteAsync(id);

        if (!deleted)
            return NotFound();

        return NoContent();
    }
}