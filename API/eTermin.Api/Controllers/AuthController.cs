using eTermin.Api.DTOs;
using eTermin.Application.DTOs;
using eTermin.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

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
    public async Task<ActionResult<AuthDto>> Register(RegisterDto registerDto)
    {
        var result = await _authService.RegisterAsync(registerDto);
        return Ok(result);
    }

    [HttpPost("login")]
    public async Task<ActionResult<AuthDto>> Login(LoginDto loginDto)
    {
        var result = await _authService.LoginAsync(loginDto);
        if (result == null)
        {
            return Unauthorized(new
            {
                message = "Email ili lozinka nisu ispravni."
            });
        }

        return Ok(result);
    }

    [HttpPut("change-password")]
    [Authorize]
    public async Task<IActionResult> ChangePassword(
        ChangePasswordDto changePasswordDto)
    {
        if (!TryGetUserId(out var userId))
            return Unauthorized();

        await _authService.ChangePasswordAsync(userId, changePasswordDto);
        return Ok(new { message = "Lozinka je uspješno promijenjena." });
    }

    [HttpPut("profile")]
    [Authorize]
    public async Task<IActionResult> UpdateProfile(
        UpdateProfileDto updateProfileDto)
    {
        if (!TryGetUserId(out var userId))
            return Unauthorized();

        await _authService.UpdateProfileAsync(userId, updateProfileDto);
        return Ok(new
        {
            message = "Podaci profila su uspješno izmijenjeni."
        });
    }

    [HttpPost("password-reset/request")]
    public async Task<IActionResult> RequestPasswordReset(
        RequestPasswordResetDto request)
    {
        await _authService.RequestPasswordResetAsync(request.Email);
        return Ok(new
        {
            message = "Ako račun postoji, kod za reset lozinke je poslan na email adresu."
        });
    }

    [HttpPost("password-reset/confirm")]
    public async Task<IActionResult> ConfirmPasswordReset(
        ResetPasswordDto request)
    {
        await _authService.ResetPasswordAsync(request);
        return Ok(new { message = "Lozinka je uspješno resetovana." });
    }

    private bool TryGetUserId(out int userId)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        return int.TryParse(userIdClaim?.Value, out userId);
    }
}
