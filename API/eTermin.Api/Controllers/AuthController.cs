using eTermin.Api.DTOs;
using eTermin.Application.DTOs;
using eTermin.Application.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using System.Net.Mail;

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

    [HttpPut("change-password")]
    [Authorize]
    public async Task<IActionResult> ChangePassword(
        ChangePasswordDto changePasswordDto)
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);

            if (userIdClaim == null)
                return Unauthorized();

            var userId = int.Parse(userIdClaim.Value);

            await _authService.ChangePasswordAsync(userId, changePasswordDto);

            return Ok(new
            {
                message = "Lozinka je uspješno promijenjena."
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                message = ex.Message
            });
        }
    }

    [HttpPut("profile")]
    [Authorize]
    public async Task<IActionResult> UpdateProfile(
        UpdateProfileDto updateProfileDto)
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);

            if (userIdClaim == null)
                return Unauthorized();

            var userId = int.Parse(userIdClaim.Value);

            await _authService.UpdateProfileAsync(userId, updateProfileDto);

            return Ok(new
            {
                message = "Podaci profila su uspješno izmijenjeni."
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                message = ex.Message
            });
        }
    }

    [HttpPost("password-reset/request")]
    public async Task<IActionResult> RequestPasswordReset(
        RequestPasswordResetDto request)
    {
        try
        {
            await _authService.RequestPasswordResetAsync(request.Email);
            return Ok(new
            {
                message = "Ako račun postoji, kod za reset lozinke je poslan na email adresu."
            });
        }
        catch (InvalidOperationException ex)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new
            {
                message = ex.Message
            });
        }
        catch (SmtpException)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new
            {
                message = "Email nije moguće poslati. Pokušajte ponovo kasnije."
            });
        }
    }

    [HttpPost("password-reset/confirm")]
    public async Task<IActionResult> ConfirmPasswordReset(
        ResetPasswordDto request)
    {
        try
        {
            await _authService.ResetPasswordAsync(request);
            return Ok(new
            {
                message = "Lozinka je uspješno resetovana."
            });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
