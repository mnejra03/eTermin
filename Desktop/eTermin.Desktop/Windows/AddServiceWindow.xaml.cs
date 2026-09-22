using System.Windows;
using eTermin.Desktop.Models;
using eTermin.Desktop.Services;

namespace eTermin.Desktop.Windows;

public partial class AddServiceWindow : Window
{
    private readonly ApiService _apiService;

    public AddServiceWindow(ApiService apiService)
    {
        InitializeComponent();

        _apiService = apiService;

        Loaded += AddServiceWindow_Loaded;
    }

    private async void AddServiceWindow_Loaded(object sender, RoutedEventArgs e)
    {
        await LoadSalonsAsync();
    }

    private async Task LoadSalonsAsync()
    {
        try
        {
            var salons = await _apiService.GetAsync<List<SalonFilterItem>>("Salons");

            if (salons == null)
                return;

            SalonComboBox.ItemsSource = salons
                .Where(x => x.Id.HasValue)
                .ToList();

            SalonComboBox.DisplayMemberPath = "Name";
            SalonComboBox.SelectedValuePath = "Id";
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška prilikom učitavanja salona:\n{ex.Message}",
                "Greška",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private async void AddButton_Click(object sender, RoutedEventArgs e)
    {
        if (SalonComboBox.SelectedValue == null)
        {
            MessageBox.Show(
                "Odaberite salon.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);

            return;
        }

        if (string.IsNullOrWhiteSpace(NameTextBox.Text))
        {
            MessageBox.Show(
                "Unesite naziv usluge.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);

            NameTextBox.Focus();
            return;
        }

        if (!int.TryParse(DurationTextBox.Text, out var duration) || duration <= 0)
        {
            MessageBox.Show(
                "Trajanje mora biti pozitivan broj minuta.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);

            DurationTextBox.Focus();
            return;
        }

        if (!decimal.TryParse(
                PriceTextBox.Text.Replace(',', '.'),
                System.Globalization.NumberStyles.Any,
                System.Globalization.CultureInfo.InvariantCulture,
                out var price)
            || price < 0)
        {
            MessageBox.Show(
                "Unesite ispravnu cijenu.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);

            PriceTextBox.Focus();
            return;
        }

        var request = new CreateServiceRequest
        {
            SalonId = (int)SalonComboBox.SelectedValue,
            Name = NameTextBox.Text.Trim(),
            Description = DescriptionTextBox.Text.Trim(),
            DurationInMinutes = duration,
            Price = price,
            IsActive = IsActiveCheckBox.IsChecked == true
        };

        try
        {
            await _apiService.PostAsync<CreateServiceRequest, object>(
                "Services",
                request);

            MessageBox.Show(
                "Usluga je uspješno dodana.",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Information);

            DialogResult = true;
            Close();
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška prilikom dodavanja usluge:\n{ex.Message}",
                "Greška",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private void CancelButton_Click(object sender, RoutedEventArgs e)
    {
        DialogResult = false;
        Close();
    }
}