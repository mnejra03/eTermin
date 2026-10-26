using eTermin.Application.DTOs;
using eTermin.Application.Services;
using eTermin.Domain.Entities;
using eTermin.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace eTermin.Infrastructure.Services;

public class NotificationService : INotificationService
{
    private readonly eTerminDbContext _context;

    public NotificationService(eTerminDbContext context)
    {
        _context = context;
    }

    public async Task<PagedResult<NotificationDto>> GetAllAsync(
        int page,
        int pageSize)
    {
        return await _context.Notifications
            .Where(n => n.Type != "AppointmentReminder" || n.CreatedAt <= DateTime.UtcNow)
            .OrderByDescending(n => n.CreatedAt)
            .ThenByDescending(n => n.Id)
            .Select(n => new NotificationDto
            {
                Id = n.Id,
                UserId = n.UserId,
                UserName = _context.Users
                    .Where(user => user.Id == n.UserId)
                    .Select(user => user.FirstName + " " + user.LastName)
                    .FirstOrDefault(),
                AppointmentId = n.AppointmentId,
                Type = n.Type,
                Title = n.Title,
                Message = n.Message,
                IsRead = n.IsRead,
                CreatedAt = n.CreatedAt
            })
            .ToPagedResultAsync(page, pageSize);
    }

    public async Task<PagedResult<NotificationDto>> GetByUserIdAsync(
        int userId,
        int page,
        int pageSize)
    {
        return await _context.Notifications
            .Where(n => n.UserId == userId &&
                (n.Type != "AppointmentReminder" || n.CreatedAt <= DateTime.UtcNow))
            .OrderByDescending(n => n.CreatedAt)
            .ThenByDescending(n => n.Id)
            .Select(n => new NotificationDto
            {
                Id = n.Id,
                UserId = n.UserId,
                AppointmentId = n.AppointmentId,
                Type = n.Type,
                Title = n.Title,
                Message = n.Message,
                IsRead = n.IsRead,
                CreatedAt = n.CreatedAt
            })
            .ToPagedResultAsync(page, pageSize);
    }

    public Task<int> GetUnreadCountByUserIdAsync(int userId, bool isAdmin)
    {
        return _context.Notifications
            .CountAsync(n => (isAdmin || n.UserId == userId) &&
                !n.IsRead &&
                (n.Type != "AppointmentReminder" ||
                    n.CreatedAt <= DateTime.UtcNow));
    }

    public async Task<NotificationDto?> GetByIdAsync(int id)
    {
        return await _context.Notifications
            .Where(n => n.Id == id)
            .Select(n => new NotificationDto
            {
                Id = n.Id,
                UserId = n.UserId,
                AppointmentId = n.AppointmentId,
                Type = n.Type,
                Title = n.Title,
                Message = n.Message,
                IsRead = n.IsRead,
                CreatedAt = n.CreatedAt
            })
            .FirstOrDefaultAsync();
    }

    public async Task<NotificationDto> CreateAsync(
        NotificationDto notificationDto)
    {
        var notification = new Notification
        {
            UserId = notificationDto.UserId,
            AppointmentId = notificationDto.AppointmentId,
            Type = notificationDto.Type,
            Title = notificationDto.Title,
            Message = notificationDto.Message,
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        };

        _context.Notifications.Add(notification);

        await _context.SaveChangesAsync();

        return new NotificationDto
        {
            Id = notification.Id,
            UserId = notification.UserId,
            AppointmentId = notification.AppointmentId,
            Type = notification.Type,
            Title = notification.Title,
            Message = notification.Message,
            IsRead = notification.IsRead,
            CreatedAt = notification.CreatedAt
        };
    }

    public async Task<bool> MarkAsReadAsync(int id, int userId, bool isAdmin)
    {
        var notification = await _context.Notifications
            .FirstOrDefaultAsync(n =>
                n.Id == id &&
                (isAdmin || n.UserId == userId));

        if (notification == null)
            return false;

        notification.IsRead = true;

        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<bool> DeleteAsync(int id, int userId, bool isAdmin)
    {
        var notification = await _context.Notifications
            .FirstOrDefaultAsync(n =>
                n.Id == id &&
                (isAdmin || n.UserId == userId));

        if (notification == null)
            return false;

        _context.Notifications.Remove(notification);

        await _context.SaveChangesAsync();

        return true;
    }
}
