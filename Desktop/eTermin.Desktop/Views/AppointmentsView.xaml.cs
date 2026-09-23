using eTermin.Desktop.Models;
using eTermin.Desktop.Services;
using eTermin.Desktop.Windows;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;

namespace eTermin.Desktop.Views;

public partial class AppointmentsView : UserControl
{
    private readonly ApiService _apiService;

    private List<AppointmentListItem> _appointments = new();
    private List<Salon> _salons = new();

    private bool _isLoadingSalons;

    private List<AppointmentListItem> _filteredAppointments = new();

    private int _currentPage = 1;

    private int PageSize
    {
        get
        {
            const double rowHeight = 48;

            var availableHeight =
                AppointmentsDataGrid.ActualHeight;

            if (availableHeight <= 0)
                return 1;

            return Math.Max(
                1,
                (int)(availableHeight / rowHeight));
        }
    }
    private int TotalPages =>
    Math.Max(
        1,
        (int)Math.Ceiling(
            _filteredAppointments.Count /
            (double)PageSize));
    private void ApplyPagination()
    {
        var pageSize = PageSize;

        if (_currentPage > TotalPages)
            _currentPage = TotalPages;

        var pagedAppointments =
            _filteredAppointments
                .Skip((_currentPage - 1) * pageSize)
                .Take(pageSize)
                .ToList();

        AppointmentsDataGrid.ItemsSource =
            pagedAppointments;

        UpdatePaginationUI();
    }
    private void UpdatePaginationUI()
    {
        PaginationPanel.Children.Clear();

        var totalItems =
            _filteredAppointments.Count;

        var pageSize = PageSize;

        var start = totalItems == 0
            ? 0
            : ((_currentPage - 1) * pageSize) + 1;

        var end = Math.Min(
            _currentPage * pageSize,
            totalItems);

        PaginationInfoText.Text =
            $"Prikazano {start}–{end} od {totalItems} termina";

        if (TotalPages <= 1)
        {
            PaginationPanel.Visibility =
                Visibility.Collapsed;

            return;
        }

        PaginationPanel.Visibility =
            Visibility.Visible;

        var previousButton =
            CreatePaginationButton("‹");

        previousButton.IsEnabled =
            _currentPage > 1;

        previousButton.Click +=
            PreviousPageButton_Click;

        PaginationPanel.Children.Add(
            previousButton);

        for (var page = 1;
             page <= TotalPages;
             page++)
        {
            var pageButton =
                CreatePaginationButton(
                    page.ToString());

            if (page == _currentPage)
            {
                pageButton.Background =
                    new SolidColorBrush(
                        Color.FromRgb(156, 39, 176));

                pageButton.Foreground =
                    Brushes.White;
            }

            var selectedPage = page;

            pageButton.Click +=
                (sender, e) =>
                {
                    _currentPage = selectedPage;
                    ApplyPagination();
                };

            PaginationPanel.Children.Add(
                pageButton);
        }

        var nextButton =
            CreatePaginationButton("›");

        nextButton.IsEnabled =
            _currentPage < TotalPages;

        nextButton.Click +=
            NextPageButton_Click;

        PaginationPanel.Children.Add(
            nextButton);
    }
    private Button CreatePaginationButton(
    string content)
    {
        return new Button
        {
            Content = content,
            Width = 34,
            Height = 34,
            Margin = new Thickness(0, 0, 5, 0),
            Background =
                System.Windows.Media.Brushes.Transparent,
            Foreground =
                new System.Windows.Media.SolidColorBrush(
                    System.Windows.Media.Color.FromRgb(
                        85,
                        85,
                        85)),
            BorderBrush =
                new System.Windows.Media.SolidColorBrush(
                    System.Windows.Media.Color.FromRgb(
                        229,
                        223,
                        232)),
            BorderThickness =
                new Thickness(1),
            FontSize = 12,
            Cursor =
                System.Windows.Input.Cursors.Hand
        };
    }
    private void PreviousPageButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        if (_currentPage <= 1)
            return;

        _currentPage--;

        ApplyPagination();
    }

    private void NextPageButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        if (_currentPage >= TotalPages)
            return;

        _currentPage++;

        ApplyPagination();
    }

    public AppointmentsView(ApiService apiService)
    {
        InitializeComponent();

        _apiService = apiService;

        Loaded += AppointmentsView_Loaded;
        SizeChanged += AppointmentsView_SizeChanged;
    }
    private void AppointmentsView_SizeChanged(
    object sender,
    SizeChangedEventArgs e)
    {
        if (!IsLoaded)
            return;

        ApplyPagination();
    }

    private async void AppointmentsView_Loaded(
        object sender,
        RoutedEventArgs e)
    {
        await LoadSalonsAsync();
        await LoadAppointmentsAsync();

        LoadStatuses();
        ApplyFilters();
    }

    // ---------------------------------------------------------
    // SALONI
    // ---------------------------------------------------------

    private async Task LoadSalonsAsync()
    {
        try
        {
            _isLoadingSalons = true;

            var salons =
                await _apiService.GetAsync<List<Salon>>("Salons");

            _salons =
                salons ?? new List<Salon>();

            var filterItems =
                new List<SalonFilterItem>
                {
                    new SalonFilterItem
                    {
                        Id = 0,
                        Name = "Svi saloni"
                    }
                };

            filterItems.AddRange(
                _salons.Select(salon =>
                    new SalonFilterItem
                    {
                        Id = salon.Id,
                        Name = salon.Name
                    }));

            SalonFilterComboBox.ItemsSource = filterItems;
            SalonFilterComboBox.DisplayMemberPath = "Name";
            SalonFilterComboBox.SelectedValuePath = "Id";
            SalonFilterComboBox.SelectedIndex = 0;
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška prilikom učitavanja salona:\n{ex.Message}",
                "Greška",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
        finally
        {
            _isLoadingSalons = false;
        }
    }

    // ---------------------------------------------------------
    // TERMINI
    // ---------------------------------------------------------

    private async Task LoadAppointmentsAsync()
    {
        try
        {
            var appointments =
                await _apiService.GetAsync<List<AppointmentListItem>>(
                    "Appointments/admin");

            _appointments =
                appointments ?? new List<AppointmentListItem>();
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška prilikom učitavanja termina:\n{ex.Message}",
                "Greška",
                MessageBoxButton.OK,
                MessageBoxImage.Error);

            _appointments = new List<AppointmentListItem>();
        }
    }

    // ---------------------------------------------------------
    // STATUSI
    // ---------------------------------------------------------

    private void LoadStatuses()
    {
        StatusFilterComboBox.Items.Clear();

        StatusFilterComboBox.Items.Add("Svi");
        StatusFilterComboBox.Items.Add("Pending");
        StatusFilterComboBox.Items.Add("Confirmed");
        StatusFilterComboBox.Items.Add("Completed");
        StatusFilterComboBox.Items.Add("Cancelled");

        StatusFilterComboBox.SelectedIndex = 0;
    }

    // ---------------------------------------------------------
    // FILTER PO SALONU
    // ---------------------------------------------------------

    private void SalonFilterComboBox_SelectionChanged(
        object sender,
        SelectionChangedEventArgs e)
    {
        if (_isLoadingSalons)
            return;

        ApplyFilters();
    }

    // ---------------------------------------------------------
    // FILTER PO STATUSU
    // ---------------------------------------------------------

    private void StatusFilterComboBox_SelectionChanged(
        object sender,
        SelectionChangedEventArgs e)
    {
        ApplyFilters();
    }

    // ---------------------------------------------------------
    // PRETRAGA
    // ---------------------------------------------------------

    private void SearchTextBox_TextChanged(
    object sender,
    TextChangedEventArgs e)
    {
        SearchPlaceholderText.Visibility =
            string.IsNullOrWhiteSpace(SearchTextBox.Text)
                ? Visibility.Visible
                : Visibility.Collapsed;

        ApplyFilters();
    }

    // ---------------------------------------------------------
    // PRIMJENA FILTERA
    // ---------------------------------------------------------

    private void ApplyFilters()
    {
        if (AppointmentsDataGrid == null)
            return;

        IEnumerable<AppointmentListItem> filtered =
            _appointments;

        // Salon
        if (SalonFilterComboBox.SelectedValue is int salonId &&
            salonId != 0)
        {
            filtered =
                filtered.Where(
                    appointment =>
                        appointment.SalonId == salonId);
        }

        // Status
        var selectedStatus =
            StatusFilterComboBox.SelectedItem?.ToString();

        if (!string.IsNullOrWhiteSpace(selectedStatus) &&
            selectedStatus != "Svi")
        {
            filtered =
                filtered.Where(
                    appointment =>
                        appointment.Status == selectedStatus);
        }

        // Datum OD
        if (StartDatePicker.SelectedDate.HasValue)
        {
            var startDate =
                StartDatePicker.SelectedDate.Value.Date;

            filtered =
                filtered.Where(
                    appointment =>
                        appointment.StartTime.Date >= startDate);
        }

        // Datum DO
        if (EndDatePicker.SelectedDate.HasValue)
        {
            var endDate =
                EndDatePicker.SelectedDate.Value.Date;

            filtered =
                filtered.Where(
                    appointment =>
                        appointment.StartTime.Date <= endDate);
        }

        // Pretraga
        var searchText =
            SearchTextBox.Text?.Trim();

        if (!string.IsNullOrWhiteSpace(searchText))
        {
            searchText =
                searchText.ToLower();

            filtered =
                filtered.Where(appointment =>
                    appointment.UserName
                        .ToLower()
                        .Contains(searchText)

                    ||

                    appointment.ServiceName
                        .ToLower()
                        .Contains(searchText)

                    ||

                    appointment.SalonName
                        .ToLower()
                        .Contains(searchText));
        }

        _filteredAppointments =
    filtered
        .OrderBy(a => a.StartTime)
        .ToList();

        _currentPage = 1;

        ApplyPagination();
    }


    

    // ---------------------------------------------------------
    // RESET
    // ---------------------------------------------------------

    private void ResetButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        SearchTextBox.Clear();

        SalonFilterComboBox.SelectedIndex = 0;

        StatusFilterComboBox.SelectedIndex = 0;

        StartDatePicker.SelectedDate = null;

        EndDatePicker.SelectedDate = null;

        ApplyFilters();
    }

    // ---------------------------------------------------------
    // DODAJ TERMIN
    // ---------------------------------------------------------

    private void AddAppointmentButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        var window =
            new AddAppointmentWindow(_apiService)
            {
                Owner = Window.GetWindow(this)
            };

        var result = window.ShowDialog();

        if (result == true)
        {
            _ = RefreshAppointmentsAsync();
        }
    }

    // ---------------------------------------------------------
    // DETALJI
    // ---------------------------------------------------------

    private void DetailsAppointmentButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        if (sender is not FrameworkElement element)
            return;

        if (element.DataContext
            is not AppointmentListItem appointment)
            return;

        MessageBox.Show(
            $"Korisnik: {appointment.UserName}\n" +
            $"Usluga: {appointment.ServiceName}\n" +
            $"Salon: {appointment.SalonName}\n" +
            $"Datum: {appointment.StartTime:dd.MM.yyyy.}\n" +
            $"Vrijeme: {appointment.StartTime:HH:mm} - {appointment.EndTime:HH:mm}\n" +
            $"Status: {appointment.Status}\n" +
            $"Cijena: {appointment.Price:N2} KM",
            "Detalji termina",
            MessageBoxButton.OK,
            MessageBoxImage.Information);
    }

    // ---------------------------------------------------------
    // UREDI
    // ---------------------------------------------------------

    private void EditAppointmentButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        MessageBox.Show(
            "Uređivanje termina ćemo napraviti u sljedećem koraku.",
            "eTermin",
            MessageBoxButton.OK,
            MessageBoxImage.Information);
    }

    // ---------------------------------------------------------
    // OBRIŠI
    // ---------------------------------------------------------

    private async void DeleteAppointmentButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        if (sender is not FrameworkElement element)
            return;

        if (element.DataContext
            is not AppointmentListItem appointment)
            return;

        var result = MessageBox.Show(
            $"Da li želite obrisati termin za korisnika " +
            $"\"{appointment.UserName}\"?\n\n" +
            "Ova radnja će trajno obrisati termin.",
            "Brisanje termina",
            MessageBoxButton.YesNo,
            MessageBoxImage.Warning);

        if (result != MessageBoxResult.Yes)
            return;

        try
        {
            var deleted =
                await _apiService.DeleteAsync(
                    $"Appointments/{appointment.Id}");

            if (!deleted)
            {
                MessageBox.Show(
                    "Termin nije moguće obrisati.",
                    "eTermin",
                    MessageBoxButton.OK,
                    MessageBoxImage.Warning);

                return;
            }

            MessageBox.Show(
                "Termin je uspješno obrisan.",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Information);

            await LoadAppointmentsAsync();

            ApplyFilters();
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška pri brisanju termina:\n{ex.Message}",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    // ---------------------------------------------------------
    // MODEL ZA FILTER SALONA
    // ---------------------------------------------------------

    private class SalonFilterItem
    {
        public int Id { get; set; }

        public string Name { get; set; } = "";
    }

    private void DatePicker_SelectedDateChanged(
    object sender,
    SelectionChangedEventArgs e)
    {
        ApplyFilters();
    }

    private AppointmentListItem? GetAppointmentFromMenuItem(
    object sender)
    {
        if (sender is not MenuItem menuItem)
            return null;

        return menuItem.Tag as AppointmentListItem;
    }

    private void EditAppointmentMenuItem_Click(
    object sender,
    RoutedEventArgs e)
    {
        if (sender is not MenuItem menuItem)
            return;

        if (menuItem.Tag is not AppointmentListItem appointment)
            return;

        var window =
            new EditAppointmentWindow(
                _apiService,
                appointment)
            {
                Owner = Window.GetWindow(this)
            };

        var result = window.ShowDialog();

        if (result == true)
        {
            _ = RefreshAppointmentsAsync();
        }
    }
    private async Task RefreshAppointmentsAsync()
    {
        await LoadAppointmentsAsync();

        ApplyFilters();
    }

    private async void ConfirmedStatusMenuItem_Click(
    object sender,
    RoutedEventArgs e)
    {
        await ChangeAppointmentStatusAsync(
            sender,
            "Confirmed");
    }

    private async void CancelledStatusMenuItem_Click(
        object sender,
        RoutedEventArgs e)
    {
        await ChangeAppointmentStatusAsync(
            sender,
            "Cancelled");
    }

    private async void PendingStatusMenuItem_Click(
        object sender,
        RoutedEventArgs e)
    {
        await ChangeAppointmentStatusAsync(
            sender,
            "Pending");
    }

    private async void CompletedStatusMenuItem_Click(
        object sender,
        RoutedEventArgs e)
    {
        await ChangeAppointmentStatusAsync(
            sender,
            "Completed");
    }
    private async Task ChangeAppointmentStatusAsync(
    object sender,
    string newStatus)
    {
        if (sender is not MenuItem menuItem)
            return;

        if (menuItem.Tag is not AppointmentListItem appointment)
            return;

        try
        {
            var request = new
            {
                UserId = appointment.UserId,
                SalonId = appointment.SalonId,
                EmployeeId = appointment.EmployeeId,
                ServiceId = appointment.ServiceId,
                StartTime = appointment.StartTime,
                EndTime = appointment.EndTime,
                Status = newStatus,
                Price = appointment.Price
            };

            var updated =
                await _apiService.PutAsync(
                    $"Appointments/{appointment.Id}",
                    request);

            if (!updated)
            {
                MessageBox.Show(
                    "Status termina nije moguće promijeniti.",
                    "eTermin",
                    MessageBoxButton.OK,
                    MessageBoxImage.Warning);

                return;
            }

            await LoadAppointmentsAsync();

            ApplyFilters();
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška prilikom promjene statusa:\n{ex.Message}",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }
    private async void DeleteAppointmentMenuItem_Click(
    object sender,
    RoutedEventArgs e)
    {
        var appointment =
            GetAppointmentFromMenuItem(sender);

        if (appointment == null)
            return;

        var result = MessageBox.Show(
            $"Da li želite obrisati termin za korisnika " +
            $"\"{appointment.UserName}\"?\n\n" +
            "Ova radnja će trajno obrisati termin.",
            "Brisanje termina",
            MessageBoxButton.YesNo,
            MessageBoxImage.Warning);

        if (result != MessageBoxResult.Yes)
            return;

        try
        {
            var deleted =
                await _apiService.DeleteAsync(
                    $"Appointments/{appointment.Id}");

            if (!deleted)
            {
                MessageBox.Show(
                    "Termin nije moguće obrisati.",
                    "eTermin",
                    MessageBoxButton.OK,
                    MessageBoxImage.Warning);

                return;
            }

            await LoadAppointmentsAsync();

            ApplyFilters();
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška prilikom brisanja termina:\n{ex.Message}",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }


    

    private void ActionsButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        if (sender is not Button button)
            return;

        if (button.DataContext is not AppointmentListItem appointment)
            return;

        var menu = new ContextMenu();

        var editItem = new MenuItem
        {
            Header = "✎  Uredi termin",
            Tag = appointment
        };

        editItem.Click += EditAppointmentMenuItem_Click;

        var statusMenu = new MenuItem
        {
            Header = "⚑  Promijeni status",
            Tag = appointment
        };

        var pendingItem = new MenuItem
        {
            Header = "Pending",
            Tag = appointment,
            IsCheckable = true,
            IsChecked = appointment.Status == "Pending"
        };

        pendingItem.Click += PendingStatusMenuItem_Click;


        var confirmedItem = new MenuItem
        {
            Header = "Confirmed",
            Tag = appointment,
            IsCheckable = true,
            IsChecked = appointment.Status == "Confirmed"
        };

        confirmedItem.Click += ConfirmedStatusMenuItem_Click;


        var completedItem = new MenuItem
        {
            Header = "Completed",
            Tag = appointment,
            IsCheckable = true,
            IsChecked = appointment.Status == "Completed"
        };

        completedItem.Click += CompletedStatusMenuItem_Click;


        var cancelledItem = new MenuItem
        {
            Header = "Cancelled",
            Tag = appointment,
            IsCheckable = true,
            IsChecked = appointment.Status == "Cancelled"
        };

        cancelledItem.Click += CancelledStatusMenuItem_Click;

        statusMenu.Items.Add(pendingItem);
        statusMenu.Items.Add(confirmedItem);
        statusMenu.Items.Add(completedItem);
        statusMenu.Items.Add(cancelledItem);

        

        var deleteItem = new MenuItem
        {
            Header = "🗑  Obriši termin",
            Tag = appointment,
            Foreground = System.Windows.Media.Brushes.Firebrick
        };

        deleteItem.Click += DeleteAppointmentMenuItem_Click;

        menu.Items.Add(editItem);
        menu.Items.Add(statusMenu);
        menu.Items.Add(new Separator());
        menu.Items.Add(deleteItem);

        menu.PlacementTarget = button;
        menu.IsOpen = true;
    }
}