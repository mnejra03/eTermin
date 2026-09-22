using eTermin.Desktop.Models;
using eTermin.Desktop.Services;
using eTermin.Desktop.Windows;
using System.Windows;

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
        SearchPlaceholderText.Visibility =
            string.IsNullOrWhiteSpace(SearchTextBox.Text)
                ? Visibility.Visible
                : Visibility.Collapsed;

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

    private async void AddSalonButton_Click(
     object sender,
     RoutedEventArgs e)
    {
        var window =
            new AddSalonWindow(_apiService)
            {
                Owner = Window.GetWindow(this)
            };

        window.ShowDialog();

        await LoadSalonsAsync();
    }

    private void DetailsSalonButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        if (sender is not FrameworkElement element)
            return;

        if (element.DataContext is not Salon salon)
            return;

        var window =
            new SalonDetailsWindow(salon)
            {
                Owner = Window.GetWindow(this)
            };

        window.ShowDialog();
    }

    private async void EditSalonButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        if (sender is not FrameworkElement element)
            return;

        if (element.DataContext is not Salon salon)
            return;

        var window =
            new EditSalonWindow(
                _apiService,
                salon)
            {
                Owner = Window.GetWindow(this)
            };

        var result = window.ShowDialog();

        if (result == true)
        {
            await LoadSalonsAsync();
        }
    }

    private async void DeleteSalonButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        if (sender is not FrameworkElement element)
            return;

        if (element.DataContext is not Salon salon)
            return;

        var result = MessageBox.Show(
            $"Da li želite obrisati salon \"{salon.Name}\"?\n\n" +
            "Ova radnja će trajno obrisati salon.",
            "Brisanje salona",
            MessageBoxButton.YesNo,
            MessageBoxImage.Warning);

        if (result != MessageBoxResult.Yes)
            return;

        try
        {
            var deleted =
                await _apiService.DeleteAsync(
                    $"Salons/{salon.Id}");

            if (!deleted)
            {
                MessageBox.Show(
                    "Salon nije moguće obrisati.",
                    "eTermin",
                    MessageBoxButton.OK,
                    MessageBoxImage.Warning);

                return;
            }

            MessageBox.Show(
                "Salon je uspješno obrisan.",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Information);

            await LoadSalonsAsync();
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška pri brisanju salona:\n{ex.Message}",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private void SearchTextBox_GotFocus(
    object sender,
    RoutedEventArgs e)
    {
        SearchPlaceholderText.Visibility =
            Visibility.Collapsed;
    }

    private void SearchTextBox_LostFocus(
        object sender,
        RoutedEventArgs e)
    {
        if (string.IsNullOrWhiteSpace(SearchTextBox.Text))
        {
            SearchPlaceholderText.Visibility =
                Visibility.Visible;
        }
    }
}