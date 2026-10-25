using eTermin.Application.DTOs;
using eTermin.Application.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Hosting;
using System.IO;

using eTermin.Domain.Constants;

namespace eTermin.Api.Controllers;

[Authorize]
[Route("api/[controller]")]
[ApiController]
public class SalonsController : ControllerBase
{
    private readonly ISalonService _salonService;
    private readonly IWebHostEnvironment _environment;

    public SalonsController(
        ISalonService salonService,
        IWebHostEnvironment environment)
    {
        _salonService = salonService;
        _environment = environment;
    }

    [HttpGet]
    public async Task<ActionResult<List<SalonDto>>> GetSalons()
    {
        var salons = await _salonService.GetAllAsync();

        return Ok(salons);
    }

    [HttpGet("popular")]
    public async Task<ActionResult<List<SalonDto>>> GetPopularSalons()
    {
        var salons = await _salonService.GetPopularAsync();

        return Ok(salons);
    }

    [HttpPost]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<ActionResult<SalonDto>> CreateSalon(SalonDto salonDto)
    {
        try
        {
            var salon = await _salonService.CreateAsync(salonDto);

            return CreatedAtAction(
                nameof(GetSalon),
                new { id = salon.Id },
                salon);
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<SalonDto>> GetSalon(int id)
    {
        var salon = await _salonService.GetByIdAsync(id);

        if (salon == null)
        {
            return NotFound();
        }

        return Ok(salon);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<IActionResult> UpdateSalon(int id, SalonDto salonDto)
    {
        bool updated;
        try
        {
            updated = await _salonService.UpdateAsync(id, salonDto);
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }

        if (!updated)
        {
            return NotFound();
        }

        return NoContent();
    }

    [HttpPost("{id}/images")]
    [Authorize(Roles = UserRoles.Admin)]
    [RequestSizeLimit(6 * 1024 * 1024)]
    public async Task<ActionResult<SalonImageDto>> UploadSalonImage(
        int id,
        IFormFile file,
        [FromForm] int sortOrder = 0)
    {
        if (file == null || file.Length is <= 0 or > 5 * 1024 * 1024)
            return BadRequest(new { message = "Slika mora imati veličinu do 5 MB." });

        var extension = Path.GetExtension(file.FileName);
        var expectedContentType = extension.ToLowerInvariant() switch
        {
            ".jpg" or ".jpeg" => "image/jpeg",
            ".png" => "image/png",
            ".webp" => "image/webp",
            _ => null
        };
        if (expectedContentType == null ||
            !string.Equals(
                file.ContentType,
                expectedContentType,
                StringComparison.OrdinalIgnoreCase))
        {
            return BadRequest(new
            {
                message = "Dozvoljeni su JPG, PNG i WEBP formati."
            });
        }

        try
        {
            var uploadDirectory = Path.Combine(
                _environment.WebRootPath ??
                    Path.Combine(_environment.ContentRootPath, "wwwroot"),
                "uploads",
                "salons");
            Directory.CreateDirectory(uploadDirectory);
            var fileName = $"{Guid.NewGuid():N}{extension.ToLowerInvariant()}";
            var filePath = Path.Combine(uploadDirectory, fileName);

            try
            {
                await using (var output = System.IO.File.Create(filePath))
                {
                    await using var input = file.OpenReadStream();
                    await input.CopyToAsync(output);
                }

                var image = await _salonService.AddImageAsync(
                    id,
                    $"/uploads/salons/{fileName}",
                    sortOrder);
                if (image == null)
                {
                    System.IO.File.Delete(filePath);
                    return NotFound();
                }
                return Ok(image);
            }
            catch
            {
                if (System.IO.File.Exists(filePath))
                    System.IO.File.Delete(filePath);
                throw;
            }
        }
        catch (InvalidOperationException exception)
        {
            return BadRequest(new { message = exception.Message });
        }
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<IActionResult> DeleteSalon(int id)
    {
        bool deleted;
        try
        {
            deleted = await _salonService.DeleteAsync(id);
        }
        catch (InvalidOperationException exception)
        {
            return Conflict(new { message = exception.Message });
        }

        if (!deleted)
        {
            return NotFound();
        }

        return NoContent();
    }
}
