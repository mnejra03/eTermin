using eTermin.Application.DTOs;

namespace eTermin.Application.Services;

public interface IAuthService
{
    Task<AuthDto> RegisterAsync(RegisterDto registerDto);

    Task<AuthDto?> LoginAsync(LoginDto loginDto);
}