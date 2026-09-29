using eTermin.Application.DTOs;
using eTermin.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Text.Json;

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
        var payment = await _paymentService.GetByIdAsync(id);

        if (payment == null)
            return NotFound();

        return Ok(payment);
    }

    [HttpGet("appointment/{appointmentId}")]
    public async Task<ActionResult<List<PaymentDto>>>
        GetByAppointment(int appointmentId)
    {
        var payments =
            await _paymentService.GetByAppointmentIdAsync(
                appointmentId);

        return Ok(payments);
    }

    [HttpPost]
    public async Task<ActionResult<PaymentDto>>
        CreatePayment(PaymentDto paymentDto)
    {
        try
        {
            var payment =
                await _paymentService.CreateAsync(paymentDto);

            return Ok(payment);
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                message = ex.Message
            });
        }
    }

    [HttpPut("{id}/status")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateStatus(
        int id,
        [FromBody] string status)
    {
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
        try
        {
            var order =
    await _payPalService.CreateOrderAsync(
        request.Amount,
        request.Currency,
        request.Description);

            return Ok(new
            {
                orderId = order.OrderId,
                approvalUrl = order.ApprovalUrl
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                message = ex.Message
            });
        }
    }

    [HttpPost("paypal/capture-order")]
    public async Task<IActionResult> CapturePayPalOrder(
    [FromBody] CapturePayPalOrderRequest request)
    {
        try
        {
            var captureId =
                await _payPalService.CaptureOrderAsync(
                    request.OrderId);

            return Ok(new
            {
                captureId
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                message = ex.Message
            });
        }
    }

    [HttpGet("paypal/return")]
    [AllowAnonymous]
    public async Task<IActionResult> PayPalReturn(
    [FromQuery] string token)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(token))
            {
                return BadRequest(new
                {
                    message = "PayPal Order ID nije pronađen."
                });
            }

            var order =
                await _payPalService.GetOrderDetailsAsync(token);

            return Content(
                order,
                "application/json");
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                message = ex.Message
            });
        }
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
        try
        {
            var result =
                await _payPalService.GetOrderDetailsAsync(orderId);

            return Content(
                result,
                "application/json");
        }
        catch (Exception ex)
        {
            return BadRequest(new
            {
                message = ex.Message
            });
        }
    }
}

public class CreatePayPalOrderRequest
{
    public decimal Amount { get; set; }

    public string Currency { get; set; } = "BAM";

    public string Description { get; set; } =
        string.Empty;
}

public class CapturePayPalOrderRequest
{
    public string OrderId { get; set; } =
        string.Empty;
}

public class CaptureAuthorizationRequest
{
    public string AuthorizationId { get; set; } = string.Empty;
}