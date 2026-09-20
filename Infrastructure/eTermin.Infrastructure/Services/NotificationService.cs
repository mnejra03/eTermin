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

    public async Task<List<NotificationDto>> GetByUserIdAsync(int userId)
    {
        return await _context.Notifications
            .Where(n => n.UserId == userId)
            .OrderByDescending(n => n.CreatedAt)
            .Select(n => new NotificationDto
            {
                Id = n.Id,
                UserId = n.UserId,
                AppointmentId = n.AppointmentId,
                Title = n.Title,
                Message = n.Message,
                IsRead = n.IsRead,
                CreatedAt = n.CreatedAt
            })
            .ToListAsync();
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
            Title = notification.Title,
            Message = notification.Message,
            IsRead = notification.IsRead,
            CreatedAt = notification.CreatedAt
        };
    }

    public async Task<bool> MarkAsReadAsync(int id, int userId)
    {
        var notification = await _context.Notifications
            .FirstOrDefaultAsync(n =>
                n.Id == id &&
                n.UserId == userId);

        if (notification == null)
            return false;

        notification.IsRead = true;

        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<bool> DeleteAsync(int id, int userId)
    {
        var notification = await _context.Notifications
            .FirstOrDefaultAsync(n =>
                n.Id == id &&
                n.UserId == userId);

        if (notification == null)
            return false;

        _context.Notifications.Remove(notification);

        await _context.SaveChangesAsync();

        return true;
    }
}