using System.Windows;
using eTermin.Desktop.Models;
using eTermin.Desktop.Services;

namespace eTermin.Desktop.Views;

public partial class SalonsView : System.Windows.Controls.UserControl
{
    private readonly ApiService _apiService;

    private List<Salon> _salons = new();

    public SalonsView(ApiService apiService)
    {
        InitializeComponent();

        _apiService = apiService;

        Loaded += SalonsView_Loaded;
    }

    private async void SalonsView_Loaded(
        object sender,
        RoutedEventArgs e)
    {
        await LoadSalonsAsync();
    }

    private async Task LoadSalonsAsync()
    {
        try
        {
            var result =
                await _apiService.GetAsync<List<Salon>>(
                    "Salons");

            _salons =
                result ?? new List<Salon>();

            var totalSalons =
                _salons.Count;

            var activeSalons =
                _salons.Count(s => s.IsActive);

            var inactiveSalons =
                _salons.Count(s => !s.IsActive);

            TotalSalonsCountText.Text =
                totalSalons.ToString();

            ActiveSalonsCountText.Text =
                activeSalons.ToString();

            InactiveSalonsCountText.Text =
                inactiveSalons.ToString();

            SalonsDataGrid.ItemsSource =
                _salons;
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška pri učitavanju salona:\n{ex.Message}",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private void SearchTextBox_TextChanged(
        object sender,
        System.Windows.Controls.TextChangedEventArgs e)
    {
        var search =
            SearchTextBox.Text
                .Trim()
                .ToLower();

        if (string.IsNullOrWhiteSpace(search))
        {
            SalonsDataGrid.ItemsSource =
                _salons;

            return;
        }

        var filtered =
            _salons
                .Where(s =>
                    s.Name.ToLower().Contains(search) ||
                    s.City.ToLower().Contains(search) ||
                    s.Address.ToLower().Contains(search))
                .ToList();

        SalonsDataGrid.ItemsSource =
            filtered;
    }

    private void AddSalonButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        MessageBox.Show(
            "Dodavanje salona ćemo implementirati u sljedećem koraku.",
            "eTermin",
            MessageBoxButton.OK,
            MessageBoxImage.Information);
    }
}