using System.Net.Mail;
using System.Windows;
using eTermin.Desktop.Models;
using eTermin.Desktop.Services;

namespace eTermin.Desktop.Windows;

public partial class AddSalonWindow : Window
{
    private readonly ApiService _apiService;

    public AddSalonWindow(ApiService apiService)
    {
        InitializeComponent();

        _apiService = apiService;
    }

    private async void SaveButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        var name = NameTextBox.Text.Trim();
        var description = DescriptionTextBox.Text.Trim();
        var address = AddressTextBox.Text.Trim();
        var city = CityTextBox.Text.Trim();
        var phone = PhoneNumberTextBox.Text.Trim();
        var email = EmailTextBox.Text.Trim();
        var imageUrl = ImageUrlTextBox.Text.Trim();

        // Obavezna polja
        if (string.IsNullOrWhiteSpace(name))
        {
            MessageBox.Show(
                "Unesite naziv salona.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);

            NameTextBox.Focus();
            return;
        }

        if (string.IsNullOrWhiteSpace(address))
        {
            MessageBox.Show(
                "Unesite adresu salona.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);

            AddressTextBox.Focus();
            return;
        }

        if (string.IsNullOrWhiteSpace(city))
        {
            MessageBox.Show(
                "Unesite grad.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);

            CityTextBox.Focus();
            return;
        }

        if (string.IsNullOrWhiteSpace(phone))
        {
            MessageBox.Show(
                "Unesite broj telefona.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);

            PhoneNumberTextBox.Focus();
            return;
        }

        if (string.IsNullOrWhiteSpace(email))
        {
            MessageBox.Show(
                "Unesite email adresu.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);

            EmailTextBox.Focus();
            return;
        }

        // Provjera emaila
        try
        {
            _ = new MailAddress(email);
        }
        catch
        {
            MessageBox.Show(
                "Unesite ispravnu email adresu.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);

            EmailTextBox.Focus();
            return;
        }

        var request = new CreateSalonRequest
        {
            Name = name,
            Description = description,
            Address = address,
            City = city,
            PhoneNumber = phone,
            Email = email,
            ImageUrl = imageUrl,
            IsActive = IsActiveCheckBox.IsChecked == true
        };

        try
        {
            var response =
                await _apiService.PostAsync<CreateSalonRequest, object>(
                    "Salons",
                    request);

            MessageBox.Show(
                "Salon je uspješno dodan.",
                "Uspješno",
                MessageBoxButton.OK,
                MessageBoxImage.Information);

            Close();
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška prilikom dodavanja salona:\n\n{ex.Message}",
                "Greška",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private void CancelButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        Close();
    }
}