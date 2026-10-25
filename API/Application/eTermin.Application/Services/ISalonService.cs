using eTermin.Application.DTOs;

namespace eTermin.Application.Services;

public interface ISalonService
{
    Task<List<SalonDto>> GetAllAsync();

    Task<SalonDto?> GetByIdAsync(int id);

    Task<SalonDto> CreateAsync(SalonDto salonDto);

    Task<bool> UpdateAsync(int id, SalonDto salonDto);

    Task<SalonImageDto?> AddImageAsync(
        int salonId,
        string imageUrl,
        int sortOrder);

    Task<bool> DeleteAsync(int id);
}