using eTermin.Application.DTOs;
using eTermin.Application.Services;
using eTermin.Domain.Entities;
using eTermin.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace eTermin.Infrastructure.Services;

public class AuthService : IAuthService
{
    private readonly eTerminDbContext _context;
    private readonly IJwtService _jwtService;

    public AuthService(
        eTerminDbContext context,
        IJwtService jwtService)
    {
        _context = context;
        _jwtService = jwtService;
    }

    public async Task<AuthDto> RegisterAsync(RegisterDto registerDto)
    {
        var existingUser = await _context.Users
            .FirstOrDefaultAsync(x => x.Email == registerDto.Email);

        if (existingUser != null)
            throw new Exception("Korisnik sa ovim emailom već postoji.");

        var passwordHash =
            BCrypt.Net.BCrypt.HashPassword(registerDto.Password);

        var user = new User
        {
            FirstName = registerDto.FirstName,
            LastName = registerDto.LastName,
            Email = registerDto.Email,
            PasswordHash = passwordHash,
            Role = "User",
            CreatedAt = DateTime.UtcNow
        };

        _context.Users.Add(user);

        await _context.SaveChangesAsync();

        return new AuthDto
        {
            UserId = user.Id,
            FirstName = user.FirstName,
            LastName = user.LastName,
            Email = user.Email,
            Role = user.Role,
            Token = _jwtService.GenerateToken(
                                user.Id,
                                user.Email,
                                user.Role)
        };
    }

    public async Task<AuthDto?> LoginAsync(LoginDto loginDto)
    {
        var user = await _context.Users
            .FirstOrDefaultAsync(x => x.Email == loginDto.Email);

        if (user == null)
            return null;

        var passwordValid =
            BCrypt.Net.BCrypt.Verify(
                loginDto.Password,
                user.PasswordHash);

        if (!passwordValid)
            return null;

        return new AuthDto
        {
            UserId = user.Id,
            FirstName = user.FirstName,
            LastName = user.LastName,
            Email = user.Email,
            Role = user.Role,
            Token = _jwtService.GenerateToken(
                                    user.Id,
                                    user.Email,
                                    user.Role)
        };
    }
}