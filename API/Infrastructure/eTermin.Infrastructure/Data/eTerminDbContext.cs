using eTermin.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace eTermin.Infrastructure.Data;

public class eTerminDbContext : DbContext
{
    public eTerminDbContext(DbContextOptions<eTerminDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users { get; set; }
    public DbSet<City> Cities { get; set; }
    public DbSet<ServiceCategory> ServiceCategories { get; set; }
    public DbSet<Salon> Salons { get; set; }
    public DbSet<Employee> Employees { get; set; }
    public DbSet<EmployeeWorkingHour> EmployeeWorkingHours { get; set; }
    public DbSet<Service> Services { get; set; }
    public DbSet<EmployeeService> EmployeeServices { get; set; }
    public DbSet<Appointment> Appointments { get; set; }
    public DbSet<AppointmentStatusHistory> AppointmentStatusHistories { get; set; }
    public DbSet<Payment> Payments { get; set; }
    public DbSet<Notification> Notifications { get; set; }
    public DbSet<SalonImage> SalonImages { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Decimal precision
        modelBuilder.Entity<Service>()
            .Property(x => x.Price)
            .HasPrecision(18, 2);

        modelBuilder.Entity<Appointment>()
            .Property(x => x.Price)
            .HasPrecision(18, 2);

        modelBuilder.Entity<Payment>()
            .Property(x => x.Amount)
            .HasPrecision(18, 2);

        modelBuilder.Entity<City>()
            .ToTable("City");

        modelBuilder.Entity<ServiceCategory>()
            .ToTable("ServiceCategory");

        modelBuilder.Entity<City>()
            .Property(x => x.Name)
            .HasMaxLength(100);

        modelBuilder.Entity<City>()
            .HasIndex(x => x.Name)
            .IsUnique();

        modelBuilder.Entity<ServiceCategory>()
            .Property(x => x.Name)
            .HasMaxLength(100);

        modelBuilder.Entity<ServiceCategory>()
            .Property(x => x.Description)
            .HasMaxLength(500);

        modelBuilder.Entity<ServiceCategory>()
            .HasIndex(x => x.Name)
            .IsUnique();

        modelBuilder.Entity<Salon>()
            .HasOne<City>()
            .WithMany()
            .HasForeignKey(x => x.CityId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Service>()
            .HasOne<ServiceCategory>()
            .WithMany()
            .HasForeignKey(x => x.ServiceCategoryId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<SalonImage>()
            .Property(image => image.ImageUrl)
            .HasMaxLength(1000);

        modelBuilder.Entity<SalonImage>()
            .HasOne<Salon>()
            .WithMany(salon => salon.Images)
            .HasForeignKey(image => image.SalonId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<SalonImage>()
            .HasIndex(image => new { image.SalonId, image.SortOrder });

        modelBuilder.Entity<AppointmentStatusHistory>()
            .HasOne(history => history.Appointment)
            .WithMany(appointment => appointment.StatusHistory)
            .HasForeignKey(history => history.AppointmentId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<AppointmentStatusHistory>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(history => history.ChangedByUserId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<AppointmentStatusHistory>()
            .HasIndex(history => new { history.AppointmentId, history.ChangedAt });

        // Salon -> Employees
        modelBuilder.Entity<Employee>()
            .HasOne<Salon>()
            .WithMany()
            .HasForeignKey(x => x.SalonId)
            .OnDelete(DeleteBehavior.Restrict);

        // Salon -> Services
        modelBuilder.Entity<Service>()
            .HasOne<Salon>()
            .WithMany()
            .HasForeignKey(x => x.SalonId)
            .OnDelete(DeleteBehavior.Restrict);

        // Employee -> Services
        modelBuilder.Entity<EmployeeService>()
            .HasKey(x => new
            {
                x.EmployeeId,
                x.ServiceId
            });

        modelBuilder.Entity<EmployeeService>()
            .HasOne(x => x.Employee)
            .WithMany(x => x.EmployeeServices)
            .HasForeignKey(x => x.EmployeeId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<EmployeeWorkingHour>()
            .HasIndex(x => new { x.EmployeeId, x.DayOfWeek })
            .IsUnique();

        modelBuilder.Entity<EmployeeWorkingHour>()
            .HasOne<Employee>()
            .WithMany(x => x.WorkingSchedule)
            .HasForeignKey(x => x.EmployeeId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<EmployeeService>()
            .HasOne(x => x.Service)
            .WithMany(x => x.EmployeeServices)
            .HasForeignKey(x => x.ServiceId)
            .OnDelete(DeleteBehavior.Cascade);

        // Appointment -> User
        modelBuilder.Entity<Appointment>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        // Appointment -> Salon
        modelBuilder.Entity<Appointment>()
            .HasOne<Salon>()
            .WithMany()
            .HasForeignKey(x => x.SalonId)
            .OnDelete(DeleteBehavior.Restrict);

        // Appointment -> Employee
        modelBuilder.Entity<Appointment>()
            .HasOne<Employee>()
            .WithMany()
            .HasForeignKey(x => x.EmployeeId)
            .OnDelete(DeleteBehavior.Restrict);

        // Appointment -> Service
        modelBuilder.Entity<Appointment>()
            .HasOne<Service>()
            .WithMany()
            .HasForeignKey(x => x.ServiceId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Appointment>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(x => x.CancelledByUserId)
            .OnDelete(DeleteBehavior.Restrict);

        // Payment -> Appointment
        modelBuilder.Entity<Payment>()
            .HasOne<Appointment>()
            .WithMany()
            .HasForeignKey(x => x.AppointmentId)
            .OnDelete(DeleteBehavior.Restrict);


        // Sprečava dupliranje podsjetnika za isti termin.
        modelBuilder.Entity<Notification>()
            .HasIndex(n => new { n.AppointmentId, n.Type })
            .IsUnique()
            .HasFilter(
                "[AppointmentId] IS NOT NULL AND [Type] = N'AppointmentReminder'");


        // Notification -> User
        modelBuilder.Entity<Notification>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Notification -> Appointment
        modelBuilder.Entity<Notification>()
            .HasOne<Appointment>()
            .WithMany()
            .HasForeignKey(x => x.AppointmentId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
