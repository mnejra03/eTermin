using eTermin.Application.DTOs;
using eTermin.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eTermin.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class PaymentsController : ControllerBase
{
    private readonly IPaymentService _paymentService;

    public PaymentsController(IPaymentService paymentService)
    {
        _paymentService = paymentService;
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
}