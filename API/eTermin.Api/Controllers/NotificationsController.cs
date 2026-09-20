using System.Security.Claims;
using eTermin.Application.DTOs;
using eTermin.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

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

    [HttpGet("my")]
    public async Task<ActionResult<List<NotificationDto>>>
        GetMyNotifications()
    {
        var userIdClaim = User.FindFirst(
            ClaimTypes.NameIdentifier);

        if (userIdClaim == null)
            return Unauthorized();

        var userId = int.Parse(userIdClaim.Value);

        var notifications =
            await _notificationService.GetByUserIdAsync(userId);

        return Ok(notifications);
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
            !User.IsInRole("Admin"))
        {
            return Forbid();
        }

        return Ok(notification);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
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
                userId);

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
                userId);

        if (!deleted)
            return NotFound();

        return NoContent();
    }
}