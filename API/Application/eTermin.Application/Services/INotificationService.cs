using eTermin.Application.DTOs;

namespace eTermin.Application.Services;

public interface INotificationService
{
    Task<PagedResult<NotificationDto>> GetAllAsync(int page, int pageSize);

    Task<PagedResult<NotificationDto>> GetByUserIdAsync(
        int userId,
        int page,
        int pageSize);

    Task<int> GetUnreadCountByUserIdAsync(int userId, bool isAdmin);

    Task<NotificationDto?> GetByIdAsync(int id);

    Task<NotificationDto> CreateAsync(NotificationDto notificationDto);

    Task<bool> MarkAsReadAsync(int id, int userId, bool isAdmin);

    Task<bool> DeleteAsync(int id, int userId, bool isAdmin);
}
