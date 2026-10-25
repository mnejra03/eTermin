using eTermin.Application.DTOs;

namespace eTermin.Application.Services;

public interface IServiceCategoryService
{
    Task<List<ServiceCategoryDto>> GetAllAsync();

    Task<ServiceCategoryDto?> GetByIdAsync(int id);

    Task<ServiceCategoryDto> CreateAsync(ServiceCategoryDto categoryDto);

    Task<bool> UpdateAsync(int id, ServiceCategoryDto categoryDto);

    Task<bool> DeleteAsync(int id);
}
