using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eTermin.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddEmployeeWeeklyWorkingSchedule : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "EmployeeWorkingHours",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    EmployeeId = table.Column<int>(type: "int", nullable: false),
                    DayOfWeek = table.Column<int>(type: "int", nullable: false),
                    StartTime = table.Column<TimeSpan>(type: "time", nullable: false),
                    EndTime = table.Column<TimeSpan>(type: "time", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EmployeeWorkingHours", x => x.Id);
                    table.ForeignKey(
                        name: "FK_EmployeeWorkingHours_Employees_EmployeeId",
                        column: x => x.EmployeeId,
                        principalTable: "Employees",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.Sql(
                """
                INSERT INTO EmployeeWorkingHours (EmployeeId, DayOfWeek, StartTime, EndTime)
                SELECT e.Id, days.DayOfWeek,
                       TRY_CONVERT(time, LEFT(e.WorkingHours, 5)),
                       TRY_CONVERT(time, SUBSTRING(e.WorkingHours, 7, 5))
                FROM Employees e
                CROSS JOIN (VALUES (1), (2), (3), (4), (5), (6)) days(DayOfWeek)
                WHERE TRY_CONVERT(time, LEFT(e.WorkingHours, 5)) IS NOT NULL
                  AND TRY_CONVERT(time, SUBSTRING(e.WorkingHours, 7, 5)) IS NOT NULL
                  AND TRY_CONVERT(time, SUBSTRING(e.WorkingHours, 7, 5))
                      > TRY_CONVERT(time, LEFT(e.WorkingHours, 5));
                """);

            migrationBuilder.DropColumn(
                name: "WorkingHours",
                table: "Employees");

            migrationBuilder.CreateIndex(
                name: "IX_EmployeeWorkingHours_EmployeeId_DayOfWeek",
                table: "EmployeeWorkingHours",
                columns: new[] { "EmployeeId", "DayOfWeek" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "EmployeeWorkingHours");

            migrationBuilder.AddColumn<string>(
                name: "WorkingHours",
                table: "Employees",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");
        }
    }
}
