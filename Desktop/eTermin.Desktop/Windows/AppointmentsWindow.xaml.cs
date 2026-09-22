using System.Windows;
using System.Windows.Controls;
using eTermin.Desktop.Models;
using eTermin.Desktop.Services;

namespace eTermin.Desktop.Windows;

public partial class AppointmentsWindow : Window
{
    private readonly ApiService _apiService;
    private readonly AuthResponse _currentUser;

    private List<AppointmentListItem> _appointments = [];
    private bool _isLoading;
    private bool _isInitialized;


    public AppointmentsWindow(
        ApiService apiService,
        AuthResponse currentUser)
    {
        InitializeComponent();

        _apiService = apiService;
        _currentUser = currentUser;

        ConfigureView();

        Loaded += AppointmentsWindow_Loaded;
    }


    // -------------------------------------------------------
    // PODEŠAVANJE EKRANA PREMA ULOZI
    // -------------------------------------------------------

    private void ConfigureView()
    {
        StatusComboBox.ItemsSource = new List<string>
        {
            "Svi",
            "Pending",
            "Confirmed",
            "Cancelled",
            "Completed"
        };

        StatusComboBox.SelectedIndex = 0;

        if (_currentUser.Role == "Admin")
        {
            TitleText.Text = "Upravljanje terminima";
            SubtitleText.Text = "Pregled i upravljanje svim terminima.";

            SalonComboBox.Visibility = Visibility.Visible;
        }
        else
        {
            TitleText.Text = "Moji termini";
            SubtitleText.Text = "Pregled vaših zakazanih termina.";

            SalonComboBox.Visibility = Visibility.Collapsed;
        }
    }


    // -------------------------------------------------------
    // LOADED
    // -------------------------------------------------------

    private async void AppointmentsWindow_Loaded(
    object sender,
    RoutedEventArgs e)
    {
       // DatePicker.SelectedDate = DateTime.Today;

        await LoadSalonsAsync();

        if (_currentUser.Role == "Admin")
        {
            SalonComboBox.SelectedIndex = 0;
        }

        await LoadAppointmentsAsync();

        _isInitialized = true;

        ApplyFilters();
    }


    // -------------------------------------------------------
    // SALONI
    // -------------------------------------------------------

    private async Task LoadSalonsAsync()
    {
        if (_currentUser.Role != "Admin")
            return;

        try
        {
            var salons =
                await _apiService.GetAsync<List<SalonFilterItem>>("Salons");

            if (salons == null)
                return;

            var items = new List<SalonFilterItem>
            {
                new SalonFilterItem
                {
                    Id = null,
                    Name = "Svi saloni"
                }
            };

            items.AddRange(
                salons.Where(x => x.Id.HasValue));

            SalonComboBox.ItemsSource = items;
            SalonComboBox.DisplayMemberPath = "Name";
            SalonComboBox.SelectedValuePath = "Id";

            SalonComboBox.SelectedIndex = 0;
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


    // -------------------------------------------------------
    // TERMINI
    // -------------------------------------------------------
    private async Task LoadAppointmentsAsync()
    {
        if (_isLoading)
            return;

        try
        {
            _isLoading = true;

            string endpoint;

            if (_currentUser.Role == "Admin")
            {
                endpoint = "Appointments/admin";
            }
            else
            {
                endpoint = "Appointments/my";
            }

            var appointments =
                await _apiService.GetAsync<List<AppointmentListItem>>(
                    endpoint);

            _appointments = appointments ?? [];
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška prilikom učitavanja termina:\n{ex.Message}",
                "Greška",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
        finally
        {
            _isLoading = false;
        }
    }


    // -------------------------------------------------------
    // FILTERI
    // -------------------------------------------------------
    private void ApplyFilters()
    {
        IEnumerable<AppointmentListItem> filtered =
            _appointments;


        // DATUM
        if (DatePicker.SelectedDate.HasValue)
        {
            var selectedDate =
                DatePicker.SelectedDate.Value.Date;

            filtered = filtered.Where(x =>
                x.StartTime.Date == selectedDate);
        }


        // SALON - SAMO ADMIN
        if (_currentUser.Role == "Admin"
    && SalonComboBox.SelectedValue is int salonId)
        {
            filtered = filtered.Where(x =>
                x.SalonId == salonId);
        }


        // STATUS
        if (StatusComboBox.SelectedItem is string selectedStatus
            && selectedStatus != "Svi")
        {
            filtered = filtered.Where(x =>
                x.Status.Equals(
                    selectedStatus,
                    StringComparison.OrdinalIgnoreCase));
        }


        // PRETRAGA
        var search =
            SearchTextBox.Text.Trim();

        if (!string.IsNullOrWhiteSpace(search))
        {
            filtered = filtered.Where(x =>
                x.UserName.Contains(
                    search,
                    StringComparison.OrdinalIgnoreCase)

                ||

                x.ServiceName.Contains(
                    search,
                    StringComparison.OrdinalIgnoreCase)

                ||

                x.SalonName.Contains(
                    search,
                    StringComparison.OrdinalIgnoreCase)

                ||

                x.Status.Contains(
                    search,
                    StringComparison.OrdinalIgnoreCase));
        }


        var result = filtered
            .OrderBy(x => x.StartTime)
            .ToList();

        AppointmentsDataGrid.ItemsSource = result;

        AppointmentsCountText.Text =
            $"Prikazano {result.Count} termina";
    }


    // -------------------------------------------------------
    // EVENTI FILTERA
    // -------------------------------------------------------

    private void SalonComboBox_SelectionChanged(
    object sender,
    SelectionChangedEventArgs e)
    {
        if (!_isInitialized)
            return;

        ApplyFilters();
    }


    private void DatePicker_SelectedDateChanged(
    object sender,
    SelectionChangedEventArgs e)
    {
        if (!_isInitialized)
            return;

        ApplyFilters();
    }


    private void StatusComboBox_SelectionChanged(
    object sender,
    SelectionChangedEventArgs e)
    {
        if (!_isInitialized)
            return;

        ApplyFilters();
    }


    private void SearchTextBox_TextChanged(
    object sender,
    TextChangedEventArgs e)
    {
        if (!_isInitialized)
            return;

        ApplyFilters();
    }



    // -------------------------------------------------------
    // OSVJEŽI
    // -------------------------------------------------------

    private async void RefreshButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        // Vrati sve filtere na početno stanje

        DatePicker.SelectedDate = null;

        StatusComboBox.SelectedIndex = 0;

        SearchTextBox.Clear();

        if (_currentUser.Role == "Admin")
        {
            SalonComboBox.SelectedIndex = 0;
        }

        await LoadAppointmentsAsync();

        ApplyFilters();
    }


    private void AppointmentActionsButton_Click(
     object sender,
     RoutedEventArgs e)
    {
        if (sender is not Button button)
            return;

        if (button.DataContext is not AppointmentListItem appointment)
            return;

        var menu = new ContextMenu();

        var detailsItem = new MenuItem
        {
            Header = "Detalji"
        };

        detailsItem.Click += (_, _) =>
        {
            var window = new AppointmentDetailsWindow(
                _apiService,
                appointment)
            {
                Owner = this
            };

            window.ShowDialog();
        };

        var editItem = new MenuItem
        {
            Header = "Uredi"
        };

        editItem.Click += (_, _) =>
        {
            EditAppointment(appointment);
        };

        var deleteItem = new MenuItem
        {
            Header = "Obriši"
        };

        deleteItem.Click += async (_, _) =>
        {
            await DeleteAppointmentAsync(appointment);
        };

        menu.Items.Add(detailsItem);
        menu.Items.Add(editItem);
        menu.Items.Add(new Separator());
        menu.Items.Add(deleteItem);

        menu.PlacementTarget = button;
        menu.IsOpen = true;
    }

    private async void EditAppointment(
    AppointmentListItem appointment)
    {
        var window = new EditAppointmentWindow(
            _apiService,
            appointment)
        {
            Owner = this
        };

        if (window.ShowDialog() == true)
        {
            await LoadAppointmentsAsync();

            ApplyFilters();
        }
    }

    private async Task DeleteAppointmentAsync(
    AppointmentListItem appointment)
    {
        var result = MessageBox.Show(
            $"Da li ste sigurni da želite obrisati termin #{appointment.Id}?",
            "Potvrda brisanja",
            MessageBoxButton.YesNo,
            MessageBoxImage.Warning);

        if (result != MessageBoxResult.Yes)
            return;

        try
        {
            var response = await _apiService.DeleteAsync(
                $"Appointments/{appointment.Id}");

            if (!response)
            {
                MessageBox.Show(
                    "Termin nije moguće obrisati.",
                    "Greška",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error);

                return;
            }

            MessageBox.Show(
                "Termin je uspješno obrisan.",
                "Uspješno",
                MessageBoxButton.OK,
                MessageBoxImage.Information);

            await LoadAppointmentsAsync();
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška prilikom brisanja termina:\n\n{ex.Message}",
                "Greška",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private void AllDatesButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        DatePicker.SelectedDate = null;

        ApplyFilters();
    }
}