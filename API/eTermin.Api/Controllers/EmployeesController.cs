using eTermin.Application.DTOs;
using eTermin.Application.Services;
using Microsoft.AspNetCore.Mvc;

namespace eTermin.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class EmployeesController : ControllerBase
{
    private readonly IEmployeeService _employeeService;

    public EmployeesController(IEmployeeService employeeService)
    {
        _employeeService = employeeService;
    }

    [HttpGet]
    public async Task<ActionResult<List<EmployeeDto>>> GetEmployees()
    {
        var employees = await _employeeService.GetAllAsync();

        return Ok(employees);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<EmployeeDto>> GetEmployee(int id)
    {
        var employee = await _employeeService.GetByIdAsync(id);

        if (employee == null)
        {
            return NotFound();
        }

        return Ok(employee);
    }

    [HttpPost]
    public async Task<ActionResult<EmployeeDto>> CreateEmployee(
        EmployeeDto employeeDto)
    {
        var employee = await _employeeService.CreateAsync(employeeDto);

        return CreatedAtAction(
            nameof(GetEmployee),
            new { id = employee.Id },
            employee);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateEmployee(
        int id,
        EmployeeDto employeeDto)
    {
        var updated = await _employeeService.UpdateAsync(id, employeeDto);

        if (!updated)
        {
            return NotFound();
        }

        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteEmployee(int id)
    {
        var deleted = await _employeeService.DeleteAsync(id);

        if (!deleted)
        {
            return NotFound();
        }

        return NoContent();
    }
}