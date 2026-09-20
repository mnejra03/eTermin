using eTermin.Application.DTOs;
using eTermin.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace eTermin.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [HttpPost("register")]
    public async Task<ActionResult<AuthDto>> Register(
        RegisterDto registerDto)
    {
        try
        {
            var result =
                await _authService.RegisterAsync(registerDto);

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

    [HttpPost("login")]
    public async Task<ActionResult<AuthDto>> Login(
        LoginDto loginDto)
    {
        var result =
            await _authService.LoginAsync(loginDto);

        if (result == null)
        {
            return Unauthorized(new
            {
                message = "Email ili lozinka nisu ispravni."
            });
        }

        return Ok(result);
    }
}