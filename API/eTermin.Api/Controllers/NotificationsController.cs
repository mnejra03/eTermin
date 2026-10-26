using System.Security.Claims;
using eTermin.Application.DTOs;
using eTermin.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

using eTermin.Domain.Constants;
using eTermin.Api.QueryParameters;

namespace eTermin.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly INotificationService _notificationService;

    public NotificationsController(
        INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    [HttpGet("admin")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<ActionResult<PagedResult<NotificationDto>>> GetAllNotifications(
        int page = 1,
        int pageSize = PaginationOptions.DefaultPageSize)
    {
        (page, pageSize) = PaginationOptions.Normalize(page, pageSize);
        return Ok(await _notificationService.GetAllAsync(page, pageSize));
    }

    [HttpGet("my")]
    public async Task<ActionResult<PagedResult<NotificationDto>>>
        GetMyNotifications(
            int page = 1,
            int pageSize = PaginationOptions.DefaultPageSize)
    {
        var userIdClaim = User.FindFirst(
            ClaimTypes.NameIdentifier);

        if (userIdClaim == null)
            return Unauthorized();

        var userId = int.Parse(userIdClaim.Value);

        (page, pageSize) = PaginationOptions.Normalize(page, pageSize);

        var notifications =
            await _notificationService.GetByUserIdAsync(
                userId,
                page,
                pageSize);

        return Ok(notifications);
    }

    [HttpGet("my/unread-count")]
    public async Task<ActionResult<object>> GetMyUnreadNotificationCount()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim == null)
            return Unauthorized();

        var userId = int.Parse(userIdClaim.Value);
        var unreadCount =
            await _notificationService.GetUnreadCountByUserIdAsync(
                userId,
                User.IsInRole(UserRoles.Admin));

        return Ok(new { unreadCount });
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<NotificationDto>>
        GetNotification(int id)
    {
        var userIdClaim = User.FindFirst(
            ClaimTypes.NameIdentifier);

        if (userIdClaim == null)
            return Unauthorized();

        var userId = int.Parse(userIdClaim.Value);

        var notification =
            await _notificationService.GetByIdAsync(id);

        if (notification == null)
            return NotFound();

        if (notification.UserId != userId &&
            !User.IsInRole(UserRoles.Admin))
        {
            return Forbid();
        }

        return Ok(notification);
    }

    [HttpPost]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<ActionResult<NotificationDto>>
        CreateNotification(NotificationDto notificationDto)
    {
        var notification =
            await _notificationService.CreateAsync(
                notificationDto);

        return Ok(notification);
    }

    [HttpPut("{id}/read")]
    public async Task<IActionResult> MarkAsRead(int id)
    {
        var userIdClaim = User.FindFirst(
            ClaimTypes.NameIdentifier);

        if (userIdClaim == null)
            return Unauthorized();

        var userId = int.Parse(userIdClaim.Value);

        var updated =
            await _notificationService.MarkAsReadAsync(
                id,
                userId,
                User.IsInRole(UserRoles.Admin));

        if (!updated)
            return NotFound();

        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteNotification(int id)
    {
        var userIdClaim = User.FindFirst(
            ClaimTypes.NameIdentifier);

        if (userIdClaim == null)
            return Unauthorized();

        var userId = int.Parse(userIdClaim.Value);

        var deleted =
            await _notificationService.DeleteAsync(
                id,
                userId,
                User.IsInRole(UserRoles.Admin));

        if (!deleted)
            return NotFound();

        return NoContent();
    }
}
