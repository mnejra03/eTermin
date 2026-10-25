using eTermin.Application.DTOs;

namespace eTermin.Application.Services;

public interface INotificationService
{
    Task<List<NotificationDto>> GetByUserIdAsync(int userId);

    Task<NotificationDto?> GetByIdAsync(int id);

    Task<NotificationDto> CreateAsync(NotificationDto notificationDto);

    Task<bool> MarkAsReadAsync(int id, int userId);

    Task<bool> DeleteAsync(int id, int userId);
}