using System.Windows;
using eTermin.Desktop.Models;
using eTermin.Desktop.Services;

namespace eTermin.Desktop;

public partial class DashboardWindow : Window
{
    private readonly ApiService _apiService;
    private readonly AuthResponse _currentUser;
    private bool _isLoadingDashboard;

    public DashboardWindow(
        ApiService apiService,
        AuthResponse currentUser)
    {
        InitializeComponent();

        _apiService = apiService;
        _currentUser = currentUser;

        Loaded += DashboardWindow_Loaded;
    }

    private async void DashboardWindow_Loaded(
    object sender,
    RoutedEventArgs e)
    {
        var hour = DateTime.Now.Hour;

        var greeting = hour < 12
            ? "Dobro jutro"
            : hour < 18
                ? "Dobar dan"
                : "Dobro veče";

        GreetingText.Text =
            $"{greeting}, {_currentUser.FirstName}!";

        await LoadSalonsAsync();
        await LoadDashboardAsync();
    }

    private async Task LoadSalonsAsync()
    {
        try
        {
            var salons =
                await _apiService.GetAsync<List<Salon>>(
                    "Salons");

            var filterItems = new List<SalonFilterItem>
        {
            new SalonFilterItem
            {
                Id = null,
                Name = "Svi saloni"
            }
        };

            if (salons != null)
            {
                filterItems.AddRange(
                    salons.Select(s => new SalonFilterItem
                    {
                        Id = s.Id,
                        Name = s.Name
                    }));
            }

            SalonFilterComboBox.ItemsSource = filterItems;
            SalonFilterComboBox.DisplayMemberPath = "Name";
            SalonFilterComboBox.SelectedIndex = 0;
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

    private async Task LoadDashboardAsync()
    {
        if (_isLoadingDashboard)
            return;

        try
        {
            _isLoadingDashboard = true;

            var selectedSalon =
                SalonFilterComboBox.SelectedItem
                as SalonFilterItem;

            string statisticsEndpoint =
                "Statistics/dashboard";

            string appointmentsEndpoint =
                "Appointments/dashboard";

            if (selectedSalon?.Id.HasValue == true)
            {
                statisticsEndpoint +=
                    $"?salonId={selectedSalon.Id.Value}";

                appointmentsEndpoint +=
                    $"?salonId={selectedSalon.Id.Value}";
            }

            var statistics =
                await _apiService.GetAsync<DashboardStatistics>(
                    statisticsEndpoint);

            if (statistics == null)
            {
                MessageBox.Show(
                    "Nije moguće učitati statistiku.",
                    "eTermin",
                    MessageBoxButton.OK,
                    MessageBoxImage.Warning);

                return;
            }

            var appointments =
                await _apiService.GetAsync<List<DashboardAppointment>>(
                    appointmentsEndpoint);

            // Današnji termini
            TotalAppointmentsText.Text =
                appointments?.Count.ToString() ?? "0";

            // Ostale statistike
            TotalUsersText.Text =
                statistics.TotalUsers.ToString();

            TotalSalonsText.Text =
                statistics.TotalSalons.ToString();

            TotalRevenueText.Text =
                $"{statistics.TotalRevenue:0.00} KM";

            // Popularna usluga
            MostPopularServiceText.Text =
                statistics.MostPopularService;

            MostPopularServiceCountText.Text =
                $"{statistics.MostPopularServiceCount} rezervacija";

            // Lista današnjih termina
            TodayAppointmentsItemsControl.ItemsSource =
                appointments;
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška pri učitavanju dashboarda:\n{ex.Message}",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
        finally
        {
            _isLoadingDashboard = false;
        }
    }

    private void LogoutButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        var loginWindow = new MainWindow();
        loginWindow.Show();
        Close();
    }

    private void SettingsButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        SettingsPopup.IsOpen = !SettingsPopup.IsOpen;
    }

    private async void SalonFilterComboBox_SelectionChanged(
    object sender,
    System.Windows.Controls.SelectionChangedEventArgs e)
    {
        if (!IsLoaded)
            return;

        await LoadDashboardAsync();
    }
}