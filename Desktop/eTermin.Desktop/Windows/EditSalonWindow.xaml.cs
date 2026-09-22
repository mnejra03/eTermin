using System.Windows;
using eTermin.Desktop.Models;
using eTermin.Desktop.Services;

namespace eTermin.Desktop.Windows;

public partial class EditSalonWindow : Window
{
    private readonly ApiService _apiService;
    private readonly Salon _salon;

    public EditSalonWindow(
        ApiService apiService,
        Salon salon)
    {
        InitializeComponent();

        _apiService = apiService;
        _salon = salon;

        LoadSalonData();
    }

    private void LoadSalonData()
    {
        NameTextBox.Text =
            _salon.Name;

        DescriptionTextBox.Text =
            _salon.Description;

        AddressTextBox.Text =
            _salon.Address;

        CityTextBox.Text =
            _salon.City;

        PhoneTextBox.Text =
            _salon.PhoneNumber;

        EmailTextBox.Text =
            _salon.Email;

        ImageUrlTextBox.Text =
            _salon.ImageUrl;

        IsActiveCheckBox.IsChecked =
            _salon.IsActive;
    }

    private async void SaveButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        if (string.IsNullOrWhiteSpace(NameTextBox.Text))
        {
            MessageBox.Show(
                "Naziv salona je obavezan.",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);

            return;
        }

        var request = new Salon
        {
            Id = _salon.Id,
            Name = NameTextBox.Text.Trim(),
            Description = DescriptionTextBox.Text.Trim(),
            Address = AddressTextBox.Text.Trim(),
            City = CityTextBox.Text.Trim(),
            PhoneNumber = PhoneTextBox.Text.Trim(),
            Email = EmailTextBox.Text.Trim(),
            ImageUrl = ImageUrlTextBox.Text.Trim(),
            IsActive = IsActiveCheckBox.IsChecked == true
        };

        try
        {
            await _apiService.PutAsync(
                $"Salons/{_salon.Id}",
                request);

            MessageBox.Show(
                "Podaci o salonu su uspješno ažurirani.",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Information);

            DialogResult = true;
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška pri ažuriranju salona:\n{ex.Message}",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private void CancelButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        DialogResult = false;
    }
}