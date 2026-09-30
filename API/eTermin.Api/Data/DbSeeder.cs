using eTermin.Domain.Entities;
using eTermin.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace eTermin.Api.Data;

public static class DbSeeder
{
    public static async Task SeedAsync(
        eTerminDbContext context)
    {
        var adminPassword =
    Environment.GetEnvironmentVariable("Seed__AdminPassword")
    ?? throw new InvalidOperationException(
        "Seed__AdminPassword nije konfigurisan.");

        var userPassword =
            Environment.GetEnvironmentVariable("Seed__UserPassword")
            ?? throw new InvalidOperationException(
                "Seed__UserPassword nije konfigurisan.");


        // =========================================================
        // PROVJERA
        // =========================================================

        await context.Database.MigrateAsync();

        // Ako već postoji naš admin korisnik,
        // smatramo da je seed već izvršen.
        var seedAdminExists =
            await context.Users
                .AnyAsync(x =>
                    x.Email == "admin@etermin.ba");

        if (seedAdminExists)
            return;


        // =========================================================
        // USERS
        // =========================================================

        var admin = new User
        {
            FirstName = "Admin",
            LastName = "eTermin",
            Email = "admin@etermin.ba",
            PasswordHash =
               BCrypt.Net.BCrypt.HashPassword(
    adminPassword),
            Role = "Admin",
            CreatedAt = DateTime.UtcNow
        };

        var user1 = new User
        {
            FirstName = "Nejra",
            LastName = "Muminović",
            Email = "nejra@etermin.ba",
            PasswordHash =
               BCrypt.Net.BCrypt.HashPassword(
    userPassword),
            Role = "User",
            CreatedAt = DateTime.UtcNow
        };

        var user2 = new User
        {
            FirstName = "Sara",
            LastName = "Marić",
            Email = "sara@etermin.ba",
            PasswordHash =
               BCrypt.Net.BCrypt.HashPassword(
    userPassword),
            Role = "User",
            CreatedAt = DateTime.UtcNow
        };

        context.Users.AddRange(
            admin,
            user1,
            user2);

        await context.SaveChangesAsync();


        // =========================================================
        // SALONS
        // =========================================================

        var salon1 = new Salon
        {
            Name = "Belle Studio",
            Description =
                "Moderan frizerski i beauty salon.",
            Address = "Ulica kralja Tomislava 12",
            City = "Mostar",
            PhoneNumber = "+387 36 123 456",
            Email = "info@belle-studio.ba",
            ImageUrl = "",
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        var salon2 = new Salon
        {
            Name = "Glow Beauty",
            Description =
                "Salon posvećen njezi lica i tijela.",
            Address = "Kneza Mihajla 8",
            City = "Mostar",
            PhoneNumber = "+387 36 234 567",
            Email = "info@glow-beauty.ba",
            ImageUrl = "",
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        var salon3 = new Salon
        {
            Name = "Beauty Studio",
            Description =
                "Beauty studio sa modernim uslugama.",
            Address = "Maršala Tita 25",
            City = "Sarajevo",
            PhoneNumber = "+387 33 345 678",
            Email = "info@beauty-studio.ba",
            ImageUrl = "",
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        var salon4 = new Salon
        {
            Name = "Elegance Beauty Studio",
            Description =
                "Elegantni salon za ljepotu i njegu.",
            Address = "Zmaja od Bosne 15",
            City = "Sarajevo",
            PhoneNumber = "+387 33 456 789",
            Email = "info@elegance.ba",
            ImageUrl = "",
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        context.Salons.AddRange(
            salon1,
            salon2,
            salon3,
            salon4);

        await context.SaveChangesAsync();


        // =========================================================
        // SERVICES
        // =========================================================

        // -------------------------
        // BELLE STUDIO
        // -------------------------

        var service1 = new Service
        {
            SalonId = salon1.Id,
            Name = "Šišanje",
            Description =
                "Žensko ili muško šišanje.",
            DurationInMinutes = 60,
            Price = 25m,
            IsActive = true
        };

        var service2 = new Service
        {
            SalonId = salon1.Id,
            Name = "Farbanje kose",
            Description =
                "Profesionalno farbanje kose.",
            DurationInMinutes = 120,
            Price = 60m,
            IsActive = true
        };

        var service3 = new Service
        {
            SalonId = salon1.Id,
            Name = "Manikir",
            Description =
                "Klasični manikir.",
            DurationInMinutes = 45,
            Price = 20m,
            IsActive = true
        };


        // -------------------------
        // GLOW BEAUTY
        // -------------------------

        var service4 = new Service
        {
            SalonId = salon2.Id,
            Name = "Tretman lica",
            Description =
                "Osnovni tretman njege lica.",
            DurationInMinutes = 60,
            Price = 35m,
            IsActive = true
        };

        var service5 = new Service
        {
            SalonId = salon2.Id,
            Name = "Masaža",
            Description =
                "Relax masaža cijelog tijela.",
            DurationInMinutes = 60,
            Price = 40m,
            IsActive = true
        };

        var service6 = new Service
        {
            SalonId = salon2.Id,
            Name = "Feniranje",
            Description =
                "Profesionalno feniranje.",
            DurationInMinutes = 45,
            Price = 18m,
            IsActive = true
        };


        // -------------------------
        // BEAUTY STUDIO
        // -------------------------

        var service7 = new Service
        {
            SalonId = salon3.Id,
            Name = "Šminkanje",
            Description =
                "Profesionalno dnevno ili večernje šminkanje.",
            DurationInMinutes = 60,
            Price = 40m,
            IsActive = true
        };

        var service8 = new Service
        {
            SalonId = salon3.Id,
            Name = "Lash Lift",
            Description =
                "Podizanje i oblikovanje prirodnih trepavica.",
            DurationInMinutes = 60,
            Price = 35m,
            IsActive = true
        };

        var service9 = new Service
        {
            SalonId = salon3.Id,
            Name = "Oblikovanje obrva",
            Description =
                "Oblikovanje i uređivanje obrva.",
            DurationInMinutes = 30,
            Price = 15m,
            IsActive = true
        };


        // -------------------------
        // ELEGANCE BEAUTY STUDIO
        // -------------------------

        var service10 = new Service
        {
            SalonId = salon4.Id,
            Name = "Pedikir",
            Description =
                "Klasični pedikir i njega stopala.",
            DurationInMinutes = 60,
            Price = 30m,
            IsActive = true
        };

        var service11 = new Service
        {
            SalonId = salon4.Id,
            Name = "Gel nokti",
            Description =
                "Izrada i oblikovanje gel noktiju.",
            DurationInMinutes = 90,
            Price = 45m,
            IsActive = true
        };

        var service12 = new Service
        {
            SalonId = salon4.Id,
            Name = "Depilacija",
            Description =
                "Profesionalna depilacija.",
            DurationInMinutes = 45,
            Price = 25m,
            IsActive = true
        };


        context.Services.AddRange(
            service1,
            service2,
            service3,
            service4,
            service5,
            service6,
            service7,
            service8,
            service9,
            service10,
            service11,
            service12);

        await context.SaveChangesAsync();


        // =========================================================
        // EMPLOYEES
        // =========================================================

        // -------------------------
        // BELLE STUDIO
        // -------------------------

        var employee1 = new Employee
        {
            SalonId = salon1.Id,
            FirstName = "Amra",
            LastName = "Hadžić",
            Email = "amra@belle-studio.ba",
            PhoneNumber = "+387 61 111 111",
            Position = "Frizer",
            WorkingHours = "08:00-16:00",
            IsActive = true
        };

        var employee2 = new Employee
        {
            SalonId = salon1.Id,
            FirstName = "Lejla",
            LastName = "Kovač",
            Email = "lejla@belle-studio.ba",
            PhoneNumber = "+387 61 222 222",
            Position = "Nail technician",
            WorkingHours = "10:00-18:00",
            IsActive = true
        };


        // -------------------------
        // GLOW BEAUTY
        // -------------------------

        var employee3 = new Employee
        {
            SalonId = salon2.Id,
            FirstName = "Sara",
            LastName = "Marić",
            Email = "sara@glow-beauty.ba",
            PhoneNumber = "+387 61 333 333",
            Position = "Beauty terapeut",
            WorkingHours = "08:00-16:00",
            IsActive = true
        };

        var employee4 = new Employee
        {
            SalonId = salon2.Id,
            FirstName = "Amina",
            LastName = "Delić",
            Email = "amina@glow-beauty.ba",
            PhoneNumber = "+387 61 444 444",
            Position = "Maser",
            WorkingHours = "09:00-17:00",
            IsActive = true
        };


        // -------------------------
        // BEAUTY STUDIO
        // -------------------------

        var employee5 = new Employee
        {
            SalonId = salon3.Id,
            FirstName = "Hana",
            LastName = "Softić",
            Email = "hana@beauty-studio.ba",
            PhoneNumber = "+387 61 555 555",
            Position = "Make-up artist",
            WorkingHours = "09:00-17:00",
            IsActive = true
        };

        var employee6 = new Employee
        {
            SalonId = salon3.Id,
            FirstName = "Emina",
            LastName = "Karić",
            Email = "emina@beauty-studio.ba",
            PhoneNumber = "+387 61 666 666",
            Position = "Beauty terapeut",
            WorkingHours = "10:00-18:00",
            IsActive = true
        };


        // -------------------------
        // ELEGANCE BEAUTY STUDIO
        // -------------------------

        var employee7 = new Employee
        {
            SalonId = salon4.Id,
            FirstName = "Mia",
            LastName = "Jukić",
            Email = "mia@elegance.ba",
            PhoneNumber = "+387 61 777 777",
            Position = "Nail technician",
            WorkingHours = "08:00-16:00",
            IsActive = true
        };

        var employee8 = new Employee
        {
            SalonId = salon4.Id,
            FirstName = "Aida",
            LastName = "Bećirović",
            Email = "aida@elegance.ba",
            PhoneNumber = "+387 61 888 888",
            Position = "Beauty terapeut",
            WorkingHours = "09:00-17:00",
            IsActive = true
        };


        context.Employees.AddRange(
            employee1,
            employee2,
            employee3,
            employee4,
            employee5,
            employee6,
            employee7,
            employee8);

        await context.SaveChangesAsync();


        // =========================================================
        // EMPLOYEE - SERVICE
        // =========================================================

        context.EmployeeServices.AddRange(

            // -------------------------
            // BELLE STUDIO
            // -------------------------

            // Amra - šišanje i farbanje
            new EmployeeService
            {
                EmployeeId = employee1.Id,
                ServiceId = service1.Id
            },

            new EmployeeService
            {
                EmployeeId = employee1.Id,
                ServiceId = service2.Id
            },

            // Lejla - manikir i šišanje
            new EmployeeService
            {
                EmployeeId = employee2.Id,
                ServiceId = service3.Id
            },

            new EmployeeService
            {
                EmployeeId = employee2.Id,
                ServiceId = service1.Id
            },


            // -------------------------
            // GLOW BEAUTY
            // -------------------------

            // Sara - tretman lica i feniranje
            new EmployeeService
            {
                EmployeeId = employee3.Id,
                ServiceId = service4.Id
            },

            new EmployeeService
            {
                EmployeeId = employee3.Id,
                ServiceId = service6.Id
            },

            // Amina - masaža i tretman lica
            new EmployeeService
            {
                EmployeeId = employee4.Id,
                ServiceId = service5.Id
            },

            new EmployeeService
            {
                EmployeeId = employee4.Id,
                ServiceId = service4.Id
            },


            // -------------------------
            // BEAUTY STUDIO
            // -------------------------

            // Hana - šminkanje i obrve
            new EmployeeService
            {
                EmployeeId = employee5.Id,
                ServiceId = service7.Id
            },

            new EmployeeService
            {
                EmployeeId = employee5.Id,
                ServiceId = service9.Id
            },

            // Emina - Lash Lift i obrve
            new EmployeeService
            {
                EmployeeId = employee6.Id,
                ServiceId = service8.Id
            },

            new EmployeeService
            {
                EmployeeId = employee6.Id,
                ServiceId = service9.Id
            },


            // -------------------------
            // ELEGANCE BEAUTY STUDIO
            // -------------------------

            // Mia - pedikir i gel nokti
            new EmployeeService
            {
                EmployeeId = employee7.Id,
                ServiceId = service10.Id
            },

            new EmployeeService
            {
                EmployeeId = employee7.Id,
                ServiceId = service11.Id
            },

            // Aida - depilacija i pedikir
            new EmployeeService
            {
                EmployeeId = employee8.Id,
                ServiceId = service12.Id
            },

            new EmployeeService
            {
                EmployeeId = employee8.Id,
                ServiceId = service10.Id
            }
        );

        await context.SaveChangesAsync();


        // =========================================================
        // APPOINTMENTS
        // =========================================================

        var today = DateTime.Today;

        // -------------------------
        // BELLE STUDIO
        // -------------------------

        var appointment1 = new Appointment
        {
            UserId = user1.Id,
            SalonId = salon1.Id,
            EmployeeId = employee1.Id,
            ServiceId = service1.Id,
            StartTime = today.AddDays(-2).AddHours(10),
            EndTime = today.AddDays(-2).AddHours(11),
            Status = "Completed",
            Price = service1.Price,
            CreatedAt = DateTime.UtcNow.AddDays(-5)
        };

        var appointment2 = new Appointment
        {
            UserId = user2.Id,
            SalonId = salon1.Id,
            EmployeeId = employee2.Id,
            ServiceId = service3.Id,
            StartTime = today.AddDays(2).AddHours(11),
            EndTime = today.AddDays(2).AddHours(11).AddMinutes(45),
            Status = "Confirmed",
            Price = service3.Price,
            CreatedAt = DateTime.UtcNow.AddDays(-1)
        };


        // -------------------------
        // GLOW BEAUTY
        // -------------------------

        var appointment3 = new Appointment
        {
            UserId = user2.Id,
            SalonId = salon2.Id,
            EmployeeId = employee3.Id,
            ServiceId = service4.Id,
            StartTime = today.AddDays(-1).AddHours(9),
            EndTime = today.AddDays(-1).AddHours(10),
            Status = "Completed",
            Price = service4.Price,
            CreatedAt = DateTime.UtcNow.AddDays(-3)
        };

        var appointment4 = new Appointment
        {
            UserId = user1.Id,
            SalonId = salon2.Id,
            EmployeeId = employee4.Id,
            ServiceId = service5.Id,
            StartTime = today.AddDays(3).AddHours(14),
            EndTime = today.AddDays(3).AddHours(15),
            Status = "Pending",
            Price = service5.Price,
            CreatedAt = DateTime.UtcNow
        };


        // -------------------------
        // BEAUTY STUDIO
        // -------------------------

        var appointment5 = new Appointment
        {
            UserId = user1.Id,
            SalonId = salon3.Id,
            EmployeeId = employee5.Id,
            ServiceId = service7.Id,
            StartTime = today.AddDays(-3).AddHours(13),
            EndTime = today.AddDays(-3).AddHours(14),
            Status = "Completed",
            Price = service7.Price,
            CreatedAt = DateTime.UtcNow.AddDays(-7)
        };

        var appointment6 = new Appointment
        {
            UserId = user2.Id,
            SalonId = salon3.Id,
            EmployeeId = employee6.Id,
            ServiceId = service8.Id,
            StartTime = today.AddDays(4).AddHours(10),
            EndTime = today.AddDays(4).AddHours(11),
            Status = "Confirmed",
            Price = service8.Price,
            CreatedAt = DateTime.UtcNow.AddDays(-1)
        };


        // -------------------------
        // ELEGANCE BEAUTY STUDIO
        // -------------------------

        var appointment7 = new Appointment
        {
            UserId = user2.Id,
            SalonId = salon4.Id,
            EmployeeId = employee7.Id,
            ServiceId = service10.Id,
            StartTime = today.AddDays(-4).AddHours(12),
            EndTime = today.AddDays(-4).AddHours(13),
            Status = "Completed",
            Price = service10.Price,
            CreatedAt = DateTime.UtcNow.AddDays(-8)
        };

        var appointment8 = new Appointment
        {
            UserId = user1.Id,
            SalonId = salon4.Id,
            EmployeeId = employee8.Id,
            ServiceId = service12.Id,
            StartTime = today.AddDays(5).AddHours(15),
            EndTime = today.AddDays(5).AddHours(15).AddMinutes(45),
            Status = "Pending",
            Price = service12.Price,
            CreatedAt = DateTime.UtcNow
        };


        context.Appointments.AddRange(
            appointment1,
            appointment2,
            appointment3,
            appointment4,
            appointment5,
            appointment6,
            appointment7,
            appointment8);

        await context.SaveChangesAsync();

    }
}