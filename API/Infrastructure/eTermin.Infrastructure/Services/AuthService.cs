using eTermin.Api.DTOs;
using eTermin.Application.DTOs;
using eTermin.Application.Services;
using eTermin.Domain.Constants;
using eTermin.Domain.Entities;
using eTermin.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;

namespace eTermin.Infrastructure.Services;

public class AuthService : IAuthService
{
    private readonly eTerminDbContext _context;
    private readonly IJwtService _jwtService;
    private readonly IEmailSender _emailSender;

    public AuthService(
        eTerminDbContext context,
        IJwtService jwtService,
        IEmailSender emailSender)
    {
        _context = context;
        _jwtService = jwtService;
        _emailSender = emailSender;
    }

    private static string NormalizeEmail(string email) =>
        email.Trim();

    public async Task<AuthDto> RegisterAsync(RegisterDto registerDto)
    {
        var normalizedEmail = NormalizeEmail(registerDto.Email);
        var existingUser = await _context.Users
            .FirstOrDefaultAsync(x => x.Email == normalizedEmail);

        if (existingUser != null)
            throw new BusinessException("Korisnik sa ovim emailom već postoji.");

        var passwordHash =
            BCrypt.Net.BCrypt.HashPassword(registerDto.Password);

        var user = new User
        {
            FirstName = registerDto.FirstName,
            LastName = registerDto.LastName,
            Email = normalizedEmail,
            PasswordHash = passwordHash,
            Role = UserRoles.User,
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
        var normalizedEmail = NormalizeEmail(loginDto.Email);
        var user = await _context.Users
            .FirstOrDefaultAsync(x =>
                EF.Functions.Collate(x.Email, "Latin1_General_CS_AS") == normalizedEmail);

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

    public async Task ChangePasswordAsync(
    int userId,
    ChangePasswordDto changePasswordDto)
    {
        var user = await _context.Users
            .FirstOrDefaultAsync(x => x.Id == userId);

        if (user == null)
            throw new NotFoundException("Korisnik ne postoji.");

        var currentPasswordValid =
            BCrypt.Net.BCrypt.Verify(
                changePasswordDto.CurrentPassword,
                user.PasswordHash);

        if (!currentPasswordValid)
            throw new BusinessException("Trenutna lozinka nije ispravna.");

        if (string.IsNullOrWhiteSpace(
                changePasswordDto.NewPassword))
        {
            throw new BusinessException(
                "Nova lozinka ne može biti prazna.");
        }

        if (changePasswordDto.NewPassword.Length < 6)
        {
            throw new BusinessException(
                "Nova lozinka mora sadržavati najmanje 6 znakova.");
        }

        if (changePasswordDto.CurrentPassword ==
            changePasswordDto.NewPassword)
        {
            throw new BusinessException(
                "Nova lozinka mora biti različita od trenutne.");
        }

        user.PasswordHash =
            BCrypt.Net.BCrypt.HashPassword(
                changePasswordDto.NewPassword);

        await _context.SaveChangesAsync();
    }

    public async Task UpdateProfileAsync(
    int userId,
    UpdateProfileDto updateProfileDto)
    {
        var user = await _context.Users
            .FirstOrDefaultAsync(x => x.Id == userId);

        if (user == null)
            throw new NotFoundException("Korisnik ne postoji.");

        if (string.IsNullOrWhiteSpace(
                updateProfileDto.FirstName))
        {
            throw new BusinessException(
                "Ime ne može biti prazno.");
        }

        if (string.IsNullOrWhiteSpace(
                updateProfileDto.LastName))
        {
            throw new BusinessException(
                "Prezime ne može biti prazno.");
        }

        if (string.IsNullOrWhiteSpace(
                updateProfileDto.Email))
        {
            throw new BusinessException(
                "Email ne može biti prazan.");
        }

        var normalizedEmail = NormalizeEmail(updateProfileDto.Email);
        var emailExists = await _context.Users
            .AnyAsync(x =>
                x.Email == normalizedEmail &&
                x.Id != userId);

        if (emailExists)
        {
            throw new BusinessException(
                "Korisnik sa ovim emailom već postoji.");
        }

        user.FirstName =
            updateProfileDto.FirstName.Trim();

        user.LastName =
            updateProfileDto.LastName.Trim();

        user.Email = normalizedEmail;

        await _context.SaveChangesAsync();
    }

    public async Task RequestPasswordResetAsync(string email)
    {
        _emailSender.EnsureConfigured();

        var normalizedEmail = NormalizeEmail(email);
        var user = await _context.Users
            .FirstOrDefaultAsync(x =>
                EF.Functions.Collate(x.Email, "Latin1_General_CS_AS") == normalizedEmail);
        if (user == null)
            return;

        var now = DateTime.UtcNow;
        var recentCodeExists = await _context.PasswordResetCodes
            .AnyAsync(x =>
                x.UserId == user.Id &&
                x.UsedAt == null &&
                x.CreatedAt > now.AddMinutes(-1));
        if (recentCodeExists)
            return;

        var previousCodes = await _context.PasswordResetCodes
            .Where(x => x.UserId == user.Id && x.UsedAt == null)
            .ToListAsync();
        foreach (var previousCode in previousCodes)
            previousCode.UsedAt = now;

        var code = RandomNumberGenerator
            .GetInt32(0, 1_000_000)
            .ToString("D6");
        var resetCode = new PasswordResetCode
        {
            UserId = user.Id,
            CodeHash = BCrypt.Net.BCrypt.HashPassword(code),
            CreatedAt = now,
            ExpiresAt = now.AddMinutes(15)
        };
        _context.PasswordResetCodes.Add(resetCode);
        await _context.SaveChangesAsync();

        await _emailSender.SendAsync(
            user.Email,
            "eTermin - kod za reset lozinke",
            $"Vaš kod za reset lozinke je: {code}\n\n" +
            "Kod vrijedi 15 minuta. Ako niste zatražili reset, " +
            "zanemarite ovu poruku.");
    }

    public async Task ResetPasswordAsync(ResetPasswordDto resetPasswordDto)
    {
        if (string.IsNullOrWhiteSpace(resetPasswordDto.NewPassword) ||
            resetPasswordDto.NewPassword.Length < 6)
        {
            throw new BusinessException(
                "Nova lozinka mora sadržavati najmanje 6 znakova.");
        }

        var email = NormalizeEmail(resetPasswordDto.Email);
        var user = await _context.Users
            .FirstOrDefaultAsync(x =>
                EF.Functions.Collate(x.Email, "Latin1_General_CS_AS") == email);
        if (user == null)
            throw new BusinessException("Kod nije ispravan ili je istekao.");

        var now = DateTime.UtcNow;
        var resetCode = await _context.PasswordResetCodes
            .Where(x =>
                x.UserId == user.Id &&
                x.UsedAt == null &&
                x.ExpiresAt > now)
            .OrderByDescending(x => x.CreatedAt)
            .FirstOrDefaultAsync();

        if (resetCode == null || resetCode.FailedAttempts >= 5)
            throw new BusinessException("Kod nije ispravan ili je istekao.");

        if (!BCrypt.Net.BCrypt.Verify(resetPasswordDto.Code, resetCode.CodeHash))
        {
            resetCode.FailedAttempts++;
            if (resetCode.FailedAttempts >= 5)
                resetCode.UsedAt = now;
            await _context.SaveChangesAsync();
            throw new BusinessException("Kod nije ispravan ili je istekao.");
        }

        user.PasswordHash =
            BCrypt.Net.BCrypt.HashPassword(resetPasswordDto.NewPassword);
        resetCode.UsedAt = now;

        var otherCodes = await _context.PasswordResetCodes
            .Where(x => x.UserId == user.Id && x.Id != resetCode.Id && x.UsedAt == null)
            .ToListAsync();
        foreach (var otherCode in otherCodes)
            otherCode.UsedAt = now;

        await _context.SaveChangesAsync();
    }
}
