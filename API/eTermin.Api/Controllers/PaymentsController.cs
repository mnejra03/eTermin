using eTermin.Application.DTOs;
using eTermin.Application.Services;
using eTermin.Domain.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace eTermin.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class PaymentsController : ControllerBase
{
    private readonly IPaymentService _paymentService;
    private readonly IPayPalService _payPalService;

    public PaymentsController(
     IPaymentService paymentService,
     IPayPalService payPalService)
    {
        _paymentService = paymentService;
        _payPalService = payPalService;
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<PaymentDto>> GetPayment(int id)
    {
        if (!TryGetUserScope(out var userId))
            return Unauthorized();

        var payment = await _paymentService.GetByIdAsync(id, userId);

        if (payment == null)
            return NotFound();

        return Ok(payment);
    }

    [HttpGet("appointment/{appointmentId}")]
    public async Task<ActionResult<List<PaymentDto>>>
        GetByAppointment(int appointmentId)
    {
        if (!TryGetUserScope(out var userId))
            return Unauthorized();

        var payments =
            await _paymentService.GetByAppointmentIdAsync(
                appointmentId,
                userId);

        if (payments == null)
            return NotFound();

        return Ok(payments);
    }

    [HttpPost]
    public async Task<ActionResult<PaymentDto>>
        CreatePayment(PaymentDto paymentDto)
    {
        if (!TryGetUserScope(out var userId))
            return Unauthorized();

        var payment = await _paymentService.CreateAsync(paymentDto, userId);

        if (payment == null)
            return NotFound(new { message = "Termin nije pronađen." });

        return Ok(payment);
    }

    [HttpPut("{id}/status")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<IActionResult> UpdateStatus(
        int id,
        [FromBody] string status)
    {
        // Only a successful PayPal capture may complete a payment.
        if (string.Equals(
                status,
                PaymentStatuses.Completed,
                StringComparison.OrdinalIgnoreCase))
        {
            return Forbid();
        }

        var updated =
            await _paymentService.UpdateStatusAsync(
                id,
                status);

        if (!updated)
            return NotFound();

        return NoContent();
    }

    [HttpPost("paypal/create-order")]
    public async Task<IActionResult> CreatePayPalOrder(
    [FromBody] CreatePayPalOrderRequest request)
    {
        if (!TryGetUserScope(out var userId))
            return Unauthorized();

        var order = await _paymentService.CreatePayPalOrderAsync(
            request.PaymentId,
            userId);

        if (order == null)
            return NotFound(new { message = "Uplata nije pronađena." });

        return Ok(new
        {
            approvalUrl = order.ApprovalUrl
        });
    }

    [HttpPost("paypal/capture-order")]
    public async Task<IActionResult> CapturePayPalOrder(
    [FromBody] CapturePayPalOrderRequest request)
    {
        if (!TryGetUserScope(out var userId))
            return Unauthorized();

        var captureId = await _paymentService.CapturePayPalOrderAsync(
            request.PaymentId,
            userId);

        if (captureId == null)
        {
            return NotFound(new
            {
                message = "Uplata nije pronađena."
            });
        }

        return Ok(new
        {
            captureId
        });
    }

    [HttpGet("paypal/return")]
    [AllowAnonymous]
    public async Task<IActionResult> PayPalReturn(
    [FromQuery] string token)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            return BadRequest(new
            {
                message = "PayPal Order ID nije pronađen."
            });
        }

        var order = await _payPalService.GetOrderDetailsAsync(token);
        return Content(order, "application/json");
    }


    [HttpGet("paypal/cancel")]
    [AllowAnonymous]
    public IActionResult PayPalCancel()
    {
        return Ok(new
        {
            message = "PayPal plaćanje je otkazano."
        });
    }

    [HttpGet("paypal/order/{orderId}")]
    public async Task<IActionResult> GetPayPalOrder(
    string orderId)
    {
        var result = await _payPalService.GetOrderDetailsAsync(orderId);
        return Content(result, "application/json");
    }

    private bool TryGetUserScope(out int? userId)
    {
        if (User.IsInRole(UserRoles.Admin))
        {
            userId = null;
            return true;
        }

        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (userIdClaim != null &&
            int.TryParse(userIdClaim.Value, out var parsedUserId))
        {
            userId = parsedUserId;
            return true;
        }

        userId = null;
        return false;
    }
}

public class CreatePayPalOrderRequest
{
    public int PaymentId { get; set; }
}

public class CapturePayPalOrderRequest
{
    public int PaymentId { get; set; }
}

public class CaptureAuthorizationRequest
{
    public string AuthorizationId { get; set; } = string.Empty;
}
