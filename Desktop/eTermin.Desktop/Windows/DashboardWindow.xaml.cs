using eTermin.Desktop.Models;
using eTermin.Desktop.Services;
using eTermin.Desktop.Views;
using LiveChartsCore;
using LiveChartsCore.SkiaSharpView;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;

namespace eTermin.Desktop.Windows;

public partial class DashboardWindow : Window
{
    private readonly ApiService _apiService;
    private readonly AuthResponse _currentUser;
    private bool _isLoadingDashboard;

    private void LoadCharts(DashboardStatistics statistics)
    {
        // ==========================================
        // GRAF 1 - REZERVACIJE PO DANIMA
        // ==========================================

        var orderedDays =
            statistics.ReservationsByDay
                .OrderBy(x => x.Date)
                .ToList();

        var dayLabels =
            orderedDays
                .Select(x =>
                    $"{GetDayName(x.Date)}\n{x.Date:dd.MM.}")
                .ToArray();

        ReservationsByDayChart.XAxes =
        [
            new Axis
        {
            Labels = dayLabels
        }
        ];

        ReservationsByDayChart.YAxes =
        [
            new Axis
        {
            Name = "Broj rezervacija"
        }
        ];

        ReservationsByDayChart.Series =
        [
            new LineSeries<int>
        {
            Values =
                orderedDays
                    .Select(x => x.Count)
                    .ToArray(),

            Fill = null
        }
        ];


        // ==========================================
        // GRAF 2 - STATUSI REZERVACIJA
        // ==========================================

        ReservationStatusChart.Series =
            statistics.ReservationsByStatus
                .Select(x => new PieSeries<int>
                {
                    Values = [x.Count],
                    Name = x.Status
                })
                .ToArray();
    }

    private string GetDayName(DateTime date)
    {
        return date.DayOfWeek switch
        {
            DayOfWeek.Monday => "PON",
            DayOfWeek.Tuesday => "UTO",
            DayOfWeek.Wednesday => "SRI",
            DayOfWeek.Thursday => "ČET",
            DayOfWeek.Friday => "PET",
            DayOfWeek.Saturday => "SUB",
            DayOfWeek.Sunday => "NED",
            _ => ""
        };
    }

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
        SetActiveSidebarButton(DashboardButton);

        await LoadSalonsAsync();
        
        await LoadDashboardAsync();
        await LoadAvailableSlotsAsync();
        await LoadNotificationBadgeAsync();
    }

    private async Task LoadAvailableSlotsAsync(int? salonId = null)
    {
        try
        {
            var endpoint = "Appointments/dashboard-available-slots";

            if (salonId.HasValue)
            {
                endpoint += $"?salonId={salonId.Value}";
            }

            var result =
                await _apiService.GetAsync<DashboardAvailableSlotsDto>(
                    endpoint);

            if (result == null)
                return;

            AvailableSlotsText.Text =
                result.AvailableSlots.ToString();

            TotalSlotsText.Text =
                $" / {result.TotalSlots}";

            AvailableSlotsProgressBar.Value =
                result.Percentage;

            AvailableSlotsPercentageText.Text =
                $"{result.Percentage}%";
        }
        catch
        {
            AvailableSlotsText.Text = "0";
            TotalSlotsText.Text = " / 0";
            AvailableSlotsProgressBar.Value = 0;
            AvailableSlotsPercentageText.Text = "0%";
        }
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

            var today = DateTime.Today;
            var tomorrow = today.AddDays(1);

            var chartFrom = today.AddDays(-6);


            // ==========================================
            // DANAŠNJA STATISTIKA - KPI KARTICE
            // ==========================================

            string todayStatisticsEndpoint =
    $"Statistics/dashboard?from={today:yyyy-MM-dd}&to={tomorrow:yyyy-MM-dd}";

            string chartStatisticsEndpoint =
                $"Statistics/dashboard?from={chartFrom:yyyy-MM-dd}&to={tomorrow:yyyy-MM-dd}";

            string appointmentsEndpoint =
                "Appointments/dashboard";

            if (selectedSalon?.Id.HasValue == true)
            {
                todayStatisticsEndpoint +=
                    $"&salonId={selectedSalon.Id.Value}";

                chartStatisticsEndpoint +=
                    $"&salonId={selectedSalon.Id.Value}";

                appointmentsEndpoint +=
                    $"?salonId={selectedSalon.Id.Value}";
            }

            var todayStatistics =
    await _apiService.GetAsync<DashboardStatistics>(
        todayStatisticsEndpoint);

            var chartStatistics =
                await _apiService.GetAsync<DashboardStatistics>(
                    chartStatisticsEndpoint);

            if (todayStatistics == null || chartStatistics == null)
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

            // ==========================================
            // STATISTIČKE KARTICE
            // ==========================================

            TotalAppointmentsText.Text =
    todayStatistics.TotalAppointments.ToString();

            TotalUsersText.Text =
                todayStatistics.TotalUsers.ToString();

            TotalSalonsText.Text =
                todayStatistics.TotalSalons.ToString();

            TotalRevenueText.Text =
                $"{todayStatistics.TotalRevenue:0.00} KM";

            MostPopularServiceText.Text =
                todayStatistics.MostPopularService;

            MostPopularServiceCountText.Text =
                $"{todayStatistics.MostPopularServiceCount} rezervacija";

            // Najaktivniji korisnik
            MostActiveUserText.Text =
                todayStatistics.MostActiveUser ?? "Nema podataka";

            MostActiveUserCountText.Text =
                $"{todayStatistics.MostActiveUserCount} rezervacija";


            // Najaktivniji salon
            MostActiveSalonText.Text =
                todayStatistics.MostActiveSalon ?? "Nema podataka";

            MostActiveSalonCountText.Text =
                $"{todayStatistics.MostActiveSalonCount} rezervacija";

            // Lista današnjih termina
            TodayAppointmentsItemsControl.ItemsSource =
                appointments;

            LoadCharts(chartStatistics);
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

        var selectedSalon =
            SalonFilterComboBox.SelectedItem as SalonFilterItem;

        int? salonId = selectedSalon?.Id;

        await LoadDashboardAsync();

        await LoadAvailableSlotsAsync(salonId);
    }


    private void StatisticsButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        SetActiveSidebarButton(StatisticsButton);

        DashboardContent.Visibility =
            Visibility.Collapsed;

        DashboardRightSidebar.Visibility =
            Visibility.Collapsed;

        MainContentControl.Content =
            new StatisticsView(_apiService);

        MainContentControl.Visibility =
            Visibility.Visible;
    }



    private async void AddServiceButton_Click(object sender, RoutedEventArgs e)
    {
        var window = new AddServiceWindow(_apiService)
        {
            Owner = this
        };

        var result = window.ShowDialog();

        if (result == true)
        {
            await LoadDashboardAsync();
        }
    }
    private async void AddEmployeeButton_Click(object sender, RoutedEventArgs e)
    {
        var window = new AddEmployeeWindow(_apiService)
        {
            Owner = this
        };

        var result = window.ShowDialog();

        if (result == true)
        {
            await LoadDashboardAsync();
        }
    }
    private async void AppointmentsButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        var window = new AppointmentsWindow(
            _apiService,
            _currentUser)
        {
            Owner = this
        };

        window.ShowDialog();

        await LoadDashboardAsync();

        var selectedSalon =
            SalonFilterComboBox.SelectedItem
            as SalonFilterItem;

        await LoadAvailableSlotsAsync(
            selectedSalon?.Id);
    }
    private void AddSalonButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        var window = new AddSalonWindow(_apiService)
        {
            Owner = this
        };

        window.ShowDialog();
    }

    private void ProfileButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        var window =
            new ProfileWindow(_currentUser)
            {
                Owner = this
            };

        window.ShowDialog();
    }

    private async void NotificationsButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        var window =
            new NotificationsWindow(_apiService)
            {
                Owner = this
            };

        window.ShowDialog();

        await LoadNotificationBadgeAsync();
    }

    private async Task LoadNotificationBadgeAsync()
    {
        try
        {
            var notifications =
                await _apiService.GetAsync<List<NotificationDto>>(
                    "Notifications/my");

            var unreadCount =
                notifications?
                    .Count(x => !x.IsRead) ?? 0;

            NotificationBadge.Visibility =
                unreadCount > 0
                    ? Visibility.Visible
                    : Visibility.Collapsed;
        }
        catch
        {
            NotificationBadge.Visibility =
                Visibility.Collapsed;
        }
    }

    private void SaloniButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        SetActiveSidebarButton(SalonsButton);

        DashboardContent.Visibility =
            Visibility.Collapsed;

        DashboardRightSidebar.Visibility =
            Visibility.Collapsed;

        MainContentControl.Content =
            new SalonsView(_apiService);

        MainContentControl.Visibility =
            Visibility.Visible;
    }

    private async void DashboardButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        SetActiveSidebarButton(DashboardButton);

        MainContentControl.Visibility =
            Visibility.Collapsed;

        MainContentControl.Content =
            null;

        DashboardContent.Visibility =
            Visibility.Visible;

        DashboardRightSidebar.Visibility =
            Visibility.Visible;

        await LoadDashboardAsync();

        var selectedSalon =
            SalonFilterComboBox.SelectedItem
            as SalonFilterItem;

        await LoadAvailableSlotsAsync(
            selectedSalon?.Id);
    }


    private void SetActiveSidebarButton(Button activeButton)
    {
        var activeColor =
            new SolidColorBrush(
                (Color)ColorConverter.ConvertFromString("#9C27B0"));

        DashboardButton.Background = Brushes.Transparent;
        SalonsButton.Background = Brushes.Transparent;
        EmployeesButton.Background = Brushes.Transparent;
        ServicesButton.Background = Brushes.Transparent;
        AppointmentsButton.Background = Brushes.Transparent;
        StatisticsButton.Background = Brushes.Transparent;

        activeButton.Background = activeColor;
    }


    private void EmployeesButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        SetActiveSidebarButton(EmployeesButton);

        DashboardContent.Visibility =
            Visibility.Collapsed;

        DashboardRightSidebar.Visibility =
            Visibility.Collapsed;

        MainContentControl.Content =
            new EmployeesView(_apiService);

        MainContentControl.Visibility =
            Visibility.Visible;
    }

    private void AppointmentsSidebarButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        SetActiveSidebarButton(AppointmentsButton);

        DashboardContent.Visibility =
            Visibility.Collapsed;

        DashboardRightSidebar.Visibility =
            Visibility.Collapsed;

        MainContentControl.Content =
            new AppointmentsView(_apiService);

        MainContentControl.Visibility =
            Visibility.Visible;
    }

    private void ServicesButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        SetActiveSidebarButton(ServicesButton);

        DashboardContent.Visibility =
            Visibility.Collapsed;

        DashboardRightSidebar.Visibility =
            Visibility.Collapsed;

        MainContentControl.Content =
            new ServicesView(_apiService);

        MainContentControl.Visibility =
            Visibility.Visible;
    }
}