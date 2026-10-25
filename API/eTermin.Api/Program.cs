using eTermin.Api.Data;
using eTermin.Api.Services;
using eTermin.Application.Services;
using eTermin.Application.Validators;
using eTermin.Domain.Entities;
using eTermin.Domain.Constants;
using eTermin.Infrastructure.Data;
using eTermin.Infrastructure.Services;
using FluentValidation;
using FluentValidation.AspNetCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using DotNetEnv;
using eTermin.Api.Middleware;

namespace eTemin.Api
{
    public class Program
    {
        public static void Main(string[] args)
        {
            Env.TraversePath().Load();

            var builder = WebApplication.CreateBuilder(args);


            var jwtKey = builder.Configuration["Jwt:Key"]
    ?? throw new InvalidOperationException(
        "JWT Key nije konfigurisan.");

            var jwtIssuer = builder.Configuration["Jwt:Issuer"];
            var jwtAudience = builder.Configuration["Jwt:Audience"];

            builder.Services.AddAuthentication(
                JwtBearerDefaults.AuthenticationScheme)
                .AddJwtBearer(options =>
                {
                    options.TokenValidationParameters = new TokenValidationParameters
                    {
                        ValidateIssuer = true,
                        ValidateAudience = true,
                        ValidateLifetime = true,
                        ValidateIssuerSigningKey = true,

                        ValidIssuer = jwtIssuer,
                        ValidAudience = jwtAudience,

                        IssuerSigningKey =
                            new SymmetricSecurityKey(
                                Encoding.UTF8.GetBytes(jwtKey))
                    };
                });

            builder.Services.AddAuthorization();


            builder.Services.AddDbContext<eTerminDbContext>(options =>
                options.UseSqlServer(
                    builder.Configuration.GetConnectionString("DefaultConnection")));

            builder.Services.AddScoped<ISalonService, SalonService>();
            builder.Services.AddScoped<ICityService, CityService>();
            builder.Services.AddScoped<IServiceCategoryService, ServiceCategoryService>();
            builder.Services.AddScoped<
                IEmployeeService,
                eTermin.Infrastructure.Services.EmployeeService>();
            builder.Services.AddScoped<IServiceService, ServiceService>();
            builder.Services.AddScoped<IAppointmentService, AppointmentService>();
            builder.Services.AddScoped<IUserService, UserService>();
            builder.Services.AddScoped<IAuthService, AuthService>();
            builder.Services.AddScoped<IEmailSender, SmtpEmailSender>();
            builder.Services.AddScoped<IJwtService, JwtService>();
            builder.Services.AddScoped<INotificationService, NotificationService>();
            builder.Services.AddScoped<IPaymentService, PaymentService>();
            builder.Services.AddScoped<IStatisticsService,StatisticsService>(); 
            builder.Services.AddScoped<IRecommendationService,RecommendationService>();
            builder.Services.AddSingleton<
                IAppointmentReminderPublisher,
                RabbitMqAppointmentReminderPublisher>();

            builder.Services.AddHttpClient<
    IPayPalService,
    PayPalService>();

            builder.Services.AddControllers();

            builder.Services.Configure<ApiBehaviorOptions>(options =>
            {
                options.InvalidModelStateResponseFactory = context =>
                {
                    var message = context.ModelState.Values
                        .SelectMany(value => value.Errors)
                        .Select(error => error.ErrorMessage)
                        .FirstOrDefault(error =>
                            !string.IsNullOrWhiteSpace(error))
                        ?? "Podaci nisu ispravni.";

                    return new BadRequestObjectResult(new { message });
                };
            });

            builder.Services.AddFluentValidationAutoValidation();
            builder.Services.AddValidatorsFromAssemblyContaining<SalonValidator>();

            builder.Services.AddEndpointsApiExplorer();

            builder.Services.AddSwaggerGen(options =>
            {
                options.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
                {
                    Name = "Authorization",
                    Type = Microsoft.OpenApi.Models.SecuritySchemeType.Http,
                    Scheme = "bearer",
                    BearerFormat = "JWT",
                    In = Microsoft.OpenApi.Models.ParameterLocation.Header,
                    Description = "Unesi JWT token u formatu: Bearer {token}"
                });

                options.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
            });

            var app = builder.Build();

            using (var scope = app.Services.CreateScope())
            {
                var services = scope.ServiceProvider;

                var context =
                    services.GetRequiredService<eTerminDbContext>();

                context.Database.Migrate();

                var resetAdminPassword =
                    app.Environment.IsDevelopment() &&
                    string.Equals(
                        Environment.GetEnvironmentVariable("ET_ADMIN_RESET_PASSWORD"),
                        "true",
                        StringComparison.OrdinalIgnoreCase);

                if (resetAdminPassword)
                {
                    var adminEmail = builder.Configuration["Docker:Seed:AdminEmail"]
                        ?? builder.Configuration["Seed:AdminEmail"]
                        ?? throw new InvalidOperationException(
                            "Docker__Seed__AdminEmail nije konfigurisan u .env fajlu.");
                    var adminPassword = builder.Configuration["Docker:Seed:AdminPassword"]
                        ?? builder.Configuration["Seed:AdminPassword"]
                        ?? throw new InvalidOperationException(
                            "Docker__Seed__AdminPassword nije konfigurisan u .env fajlu.");

                    var admin = context.Users
                        .SingleOrDefault(user => user.Email == adminEmail);

                    if (admin == null)
                    {
                        admin = new User
                        {
                            FirstName = "Admin",
                            LastName = "eTermin",
                            Email = adminEmail,
                            Role = UserRoles.Admin,
                            CreatedAt = DateTime.UtcNow
                        };
                        context.Users.Add(admin);
                    }

                    admin.Role = UserRoles.Admin;
                    admin.PasswordHash = BCrypt.Net.BCrypt.HashPassword(adminPassword);
                    context.SaveChanges();
                    app.Logger.LogInformation(
                        "Development admin password reset for configured account. Restart the API without the reset flag.");
                    return;
                }

                if (builder.Configuration.GetValue<bool>("Seed:Enabled"))
                {
                    DbSeeder.SeedAsync(context)
                        .GetAwaiter()
                        .GetResult();
                }
            }

            if (app.Environment.IsDevelopment())
            {
                app.UseSwagger();
                app.UseSwaggerUI();
            }

            app.UseStaticFiles();

            //app.UseHttpsRedirection();

            app.UseMiddleware<ExceptionHandlingMiddleware>();

            app.UseAuthentication();
            app.UseAuthorization();

            app.MapControllers();

            app.Run();
        }
    }
}
