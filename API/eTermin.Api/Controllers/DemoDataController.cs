using eTermin.Domain.Entities;
using eTermin.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace eTermin.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public class DemoDataController : ControllerBase
{
    private readonly eTerminDbContext _context;

    public DemoDataController(eTerminDbContext context)
    {
        _context = context;
    }

    [HttpPost("generate")]
    public async Task<IActionResult> Generate()
    {
        // ----------------------------------------------------
        // 1. PRONAĐI POSTOJEĆEG KORISNIKA
        // ----------------------------------------------------

        var user = await _context.Users
            .FirstOrDefaultAsync(x => x.Role == "User");

        if (user == null)
        {
            return BadRequest(new
            {
                message = "U bazi ne postoji nijedan korisnik sa ulogom User."
            });
        }

        // ----------------------------------------------------
        // 2. SALONI
        // ----------------------------------------------------

        var salons = new List<Salon>();

        var salon1 = await _context.Salons
            .FirstOrDefaultAsync(x => x.Name == "Belle Studio");

        if (salon1 == null)
        {
            salon1 = new Salon
            {
                Name = "Belle Studio",
                Description = "Salon za njegu i uljepšavanje.",
                Address = "Maršala Tita 12",
                City = "Sarajevo",
                PhoneNumber = "033/111-222",
                Email = "info@belle-studio.ba",
                ImageUrl = "",
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            _context.Salons.Add(salon1);
        }

        salons.Add(salon1);

        var salon2 = await _context.Salons
            .FirstOrDefaultAsync(x => x.Name == "Glow Beauty");

        if (salon2 == null)
        {
            salon2 = new Salon
            {
                Name = "Glow Beauty",
                Description = "Studio posvećen njezi lica, tijela i kose.",
                Address = "Zmaja od Bosne 25",
                City = "Sarajevo",
                PhoneNumber = "033/333-444",
                Email = "info@glowbeauty.ba",
                ImageUrl = "",
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            _context.Salons.Add(salon2);
        }

        salons.Add(salon2);

        await _context.SaveChangesAsync();

        // ----------------------------------------------------
        // 3. ZAPOSLENICI
        // ----------------------------------------------------

        await AddEmployeeIfMissing(
            salon1.Id,
            "Lejla",
            "Marić",
            "lejla@belle-studio.ba",
            "061/111-111",
            "Frizer",
            "08:00-16:00");

        await AddEmployeeIfMissing(
            salon1.Id,
            "Amina",
            "Softić",
            "amina@belle-studio.ba",
            "061/222-222",
            "Kozmetičar",
            "10:00-18:00");

        await AddEmployeeIfMissing(
            salon2.Id,
            "Hana",
            "Alić",
            "hana@glowbeauty.ba",
            "061/333-333",
            "Kozmetičar",
            "08:00-16:00");

        await AddEmployeeIfMissing(
            salon2.Id,
            "Emina",
            "Karić",
            "emina@glowbeauty.ba",
            "061/444-444",
            "Frizer",
            "10:00-18:00");

        await _context.SaveChangesAsync();

        // ----------------------------------------------------
        // 4. USLUGE
        // ----------------------------------------------------

        await AddServiceIfMissing(
            salon1.Id,
            "Šišanje",
            "Žensko šišanje i stilizovanje.",
            60,
            25);

        await AddServiceIfMissing(
            salon1.Id,
            "Farbanje kose",
            "Farbanje i njega kose.",
            120,
            55);

        await AddServiceIfMissing(
            salon1.Id,
            "Manikir",
            "Klasični manikir.",
            45,
            20);

        await AddServiceIfMissing(
            salon2.Id,
            "Tretman lica",
            "Dubinsko čišćenje i njega lica.",
            60,
            35);

        await AddServiceIfMissing(
            salon2.Id,
            "Masaža",
            "Relax masaža cijelog tijela.",
            60,
            40);

        await AddServiceIfMissing(
            salon2.Id,
            "Feniranje",
            "Profesionalno feniranje kose.",
            45,
            18);

        await _context.SaveChangesAsync();

        // ----------------------------------------------------
        // 5. TERMINI
        // ----------------------------------------------------

        await CreateDemoAppointments(
            salon1.Id,
            user.Id);

        await CreateDemoAppointments(
            salon2.Id,
            user.Id);

        return Ok(new
        {
            message = "Demo podaci su uspješno generisani.",
            salons = 2,
            employees = 4,
            services = 6
        });
    }

    // ========================================================
    // EMPLOYEE
    // ========================================================

    private async Task AddEmployeeIfMissing(
        int salonId,
        string firstName,
        string lastName,
        string email,
        string phone,
        string position,
        string workingHours)
    {
        var exists = await _context.Employees
            .AnyAsync(x =>
                x.SalonId == salonId &&
                x.Email == email);

        if (exists)
            return;

        _context.Employees.Add(new Employee
        {
            SalonId = salonId,
            FirstName = firstName,
            LastName = lastName,
            Email = email,
            PhoneNumber = phone,
            Position = position,
            WorkingHours = workingHours,
            IsActive = true
        });
    }

    // ========================================================
    // SERVICE
    // ========================================================

    private async Task AddServiceIfMissing(
        int salonId,
        string name,
        string description,
        int duration,
        decimal price)
    {
        var exists = await _context.Services
            .AnyAsync(x =>
                x.SalonId == salonId &&
                x.Name == name);

        if (exists)
            return;

        _context.Services.Add(new Service
        {
            SalonId = salonId,
            Name = name,
            Description = description,
            DurationInMinutes = duration,
            Price = price,
            IsActive = true
        });
    }

    // ========================================================
    // APPOINTMENTS
    // ========================================================

    private async Task CreateDemoAppointments(
        int salonId,
        int userId)
    {
        var employees = await _context.Employees
            .Where(x =>
                x.SalonId == salonId &&
                x.IsActive)
            .OrderBy(x => x.Id)
            .ToListAsync();

        var services = await _context.Services
            .Where(x =>
                x.SalonId == salonId &&
                x.IsActive)
            .OrderBy(x => x.Id)
            .ToListAsync();

        if (employees.Count == 0 ||
            services.Count == 0)
        {
            return;
        }

        var today = DateTime.Today;

        // ----------------------------------------------------
        // Termin 1 - danas
        // ----------------------------------------------------

        await AddAppointmentIfMissing(
            userId,
            salonId,
            employees[0].Id,
            services[0].Id,
            today.AddHours(12),
            "Confirmed");

        // ----------------------------------------------------
        // Termin 2 - danas
        // ----------------------------------------------------

        if (employees.Count > 1)
        {
            await AddAppointmentIfMissing(
                userId,
                salonId,
                employees[1].Id,
                services[1].Id,
                today.AddHours(14),
                "Pending");
        }

        // ----------------------------------------------------
        // Termin 3 - sutra
        // ----------------------------------------------------

        await AddAppointmentIfMissing(
            userId,
            salonId,
            employees[0].Id,
            services[2 % services.Count].Id,
            today.AddDays(1).AddHours(10),
            "Confirmed");

        // ----------------------------------------------------
        // Termin 4 - za dva dana
        // ----------------------------------------------------

        if (employees.Count > 1)
        {
            await AddAppointmentIfMissing(
                userId,
                salonId,
                employees[1].Id,
                services[0].Id,
                today.AddDays(2).AddHours(11),
                "Cancelled");
        }

        await _context.SaveChangesAsync();
    }

    private async Task AddAppointmentIfMissing(
        int userId,
        int salonId,
        int employeeId,
        int serviceId,
        DateTime startTime,
        string status)
    {
        var service = await _context.Services
            .FirstOrDefaultAsync(x => x.Id == serviceId);

        if (service == null)
            return;

        var endTime =
            startTime.AddMinutes(service.DurationInMinutes);

        var exists = await _context.Appointments
            .AnyAsync(x =>
                x.SalonId == salonId &&
                x.EmployeeId == employeeId &&
                x.StartTime == startTime);

        if (exists)
            return;

        _context.Appointments.Add(new Appointment
        {
            UserId = userId,
            SalonId = salonId,
            EmployeeId = employeeId,
            ServiceId = serviceId,
            StartTime = startTime,
            EndTime = endTime,
            Status = status,
            Price = service.Price,
            CreatedAt = DateTime.UtcNow
        });
    }
}