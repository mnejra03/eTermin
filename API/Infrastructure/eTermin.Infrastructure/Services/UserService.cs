using eTermin.Application.DTOs;
using eTermin.Application.Services;
using eTermin.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace eTermin.Infrastructure.Services;

public class UserService : IUserService
{
    private readonly eTerminDbContext _context;

    public UserService(eTerminDbContext context)
    {
        _context = context;
    }

    public async Task<List<UserDto>> GetAllAsync()
    {
        return await _context.Users
            .Select(u => new UserDto
            {
                Id = u.Id,
                FirstName = u.FirstName,
                LastName = u.LastName,
                Email = u.Email,
                Role = u.Role,
                CreatedAt = u.CreatedAt
            })
            .ToListAsync();
    }

    public async Task<UserDto?> GetByIdAsync(int id)
    {
        return await _context.Users
            .Where(u => u.Id == id)
            .Select(u => new UserDto
            {
                Id = u.Id,
                FirstName = u.FirstName,
                LastName = u.LastName,
                Email = u.Email,
                Role = u.Role,
                CreatedAt = u.CreatedAt
            })
            .FirstOrDefaultAsync();
    }

    public async Task<bool> UpdateAsync(
        int id,
        UserDto userDto)
    {
        var user = await _context.Users.FindAsync(id);

        if (user == null)
            return false;

        user.FirstName = userDto.FirstName;
        user.LastName = userDto.LastName;
        user.Email = userDto.Email;
        user.Role = userDto.Role;

        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var user = await _context.Users.FindAsync(id);

        if (user == null)
            return false;

        var hasAppointments = await _context.Appointments
            .AnyAsync(appointment =>
                appointment.UserId == id ||
                appointment.CancelledByUserId == id);

        if (hasAppointments)
            throw new InvalidOperationException(
                "Korisnik se ne može obrisati jer je povezan s terminima " +
                "ili zapisima o otkazivanju termina.");

        var hasStatusHistory = await _context.AppointmentStatusHistories
            .AnyAsync(history => history.ChangedByUserId == id);

        if (hasStatusHistory)
            throw new InvalidOperationException(
                "Korisnik se ne može obrisati jer je zabilježen kao osoba koja je promijenila status termina.");

        _context.Users.Remove(user);

        await _context.SaveChangesAsync();

        return true;
    }
}
