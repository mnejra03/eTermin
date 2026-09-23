using System.Globalization;
using System.Windows;
using System.Windows.Controls;
using eTermin.Desktop.Models;
using eTermin.Desktop.Services;

namespace eTermin.Desktop.Windows;

public partial class AddAppointmentWindow : Window
{
    private readonly ApiService _apiService;

    private List<UserFilterItem> _users = [];
    private List<SalonFilterItem> _salons = [];
    private List<ServiceFilterItem> _services = [];
    private List<EmployeeFilterItem> _employees = [];

    public AddAppointmentWindow(ApiService apiService)
    {
        InitializeComponent();

        _apiService = apiService;

        StatusComboBox.ItemsSource = new List<string>
        {
            "Pending",
            "Confirmed",
            "Completed",
            "Cancelled"
        };

        StatusComboBox.SelectedItem = "Pending";

        DatePicker.SelectedDate = DateTime.Today;

        Loaded += AddAppointmentWindow_Loaded;
    }

    private async void AddAppointmentWindow_Loaded(
        object sender,
        RoutedEventArgs e)
    {
        await LoadUsersAsync();
        await LoadSalonsAsync();
    }

    private async Task LoadUsersAsync()
    {
        try
        {
            var users =
                await _apiService.GetAsync<List<UserFilterItem>>(
                    "Users");

            _users = users ?? [];

            UserComboBox.ItemsSource = _users;
            UserComboBox.DisplayMemberPath = "Name";
            UserComboBox.SelectedValuePath = "Id";
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška prilikom učitavanja korisnika:\n{ex.Message}",
                "Greška",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private async Task LoadSalonsAsync()
    {
        try
        {
            var salons =
                await _apiService.GetAsync<List<SalonFilterItem>>(
                    "Salons");

            _salons = salons ?? [];

            SalonComboBox.ItemsSource = _salons;
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

    private async Task LoadServicesAsync(int salonId)
    {
        try
        {
            var services =
                await _apiService.GetAsync<List<ServiceFilterItem>>(
                    "Services");

            

            

            _services = services?
                .Where(x =>
                    x.SalonId == salonId &&
                    x.IsActive)
                .ToList()
                ?? [];

            ServiceComboBox.ItemsSource = _services;
            ServiceComboBox.DisplayMemberPath = "Name";
            ServiceComboBox.SelectedValuePath = "Id";

            EmployeeComboBox.ItemsSource = null;
            PriceTextBox.Text = "";
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška prilikom učitavanja usluga:\n{ex.Message}",
                "Greška",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private async Task LoadEmployeesAsync(int salonId)
    {
        try
        {
            var employees =
                await _apiService.GetAsync<List<EmployeeFilterItem>>(
                    "Employees");

            

            _employees = employees?
                .Where(x => x.SalonId == salonId)
                .ToList()
                ?? [];

            EmployeeComboBox.ItemsSource = _employees;
            EmployeeComboBox.DisplayMemberPath = "Name";
            EmployeeComboBox.SelectedValuePath = "Id";
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška prilikom učitavanja zaposlenika:\n{ex.Message}",
                "Greška",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private async void SalonComboBox_SelectionChanged(
        object sender,
        SelectionChangedEventArgs e)
    {
        if (SalonComboBox.SelectedValue is not int salonId)
            return;

        await LoadServicesAsync(salonId);
        await LoadEmployeesAsync(salonId);
    }

    private void ServiceComboBox_SelectionChanged(
        object sender,
        SelectionChangedEventArgs e)
    {
        if (ServiceComboBox.SelectedItem is not ServiceFilterItem service)
        {
            PriceTextBox.Text = "";
            return;
        }

        PriceTextBox.Text =
            service.Price.ToString(
                "0.00",
                CultureInfo.InvariantCulture);
    }

    private async void SaveButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        if (UserComboBox.SelectedValue is not int userId)
        {
            MessageBox.Show(
                "Odaberite korisnika.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);
            return;
        }

        if (SalonComboBox.SelectedValue is not int salonId)
        {
            MessageBox.Show(
                "Odaberite salon.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);
            return;
        }

        if (ServiceComboBox.SelectedValue is not int serviceId)
        {
            MessageBox.Show(
                "Odaberite uslugu.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);
            return;
        }

        if (EmployeeComboBox.SelectedValue is not int employeeId)
        {
            MessageBox.Show(
                "Odaberite zaposlenika.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);
            return;
        }

        if (!DatePicker.SelectedDate.HasValue)
        {
            MessageBox.Show(
                "Odaberite datum.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);
            return;
        }

        if (!TimeSpan.TryParse(
                StartTimeTextBox.Text,
                out var startTime))
        {
            MessageBox.Show(
                "Vrijeme mora biti u formatu HH:mm.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);
            return;
        }

        if (StatusComboBox.SelectedItem is not string status)
        {
            MessageBox.Show(
                "Odaberite status.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);
            return;
        }

        if (ServiceComboBox.SelectedItem
            is not ServiceFilterItem selectedService)
        {
            MessageBox.Show(
                "Odaberite uslugu.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);
            return;
        }

        var selectedDate =
            DatePicker.SelectedDate.Value.Date;

        var startDateTime =
            selectedDate + startTime;

        var endDateTime =
            startDateTime.AddMinutes(
                selectedService.DurationInMinutes);

        var request = new CreateAppointmentRequest
        {
            UserId = userId,
            SalonId = salonId,
            EmployeeId = employeeId,
            ServiceId = serviceId,
            StartTime = startDateTime,
            EndTime = endDateTime,
            Status = status,
            Price = selectedService.Price
        };

        try
        {
            var created =
                await _apiService.PostAsync<CreateAppointmentRequest, Appointment>(
                    "Appointments",
                    request);

            if (created == null)
            {
                MessageBox.Show(
                    "Termin nije moguće dodati.",
                    "Greška",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error);

                return;
            }

            MessageBox.Show(
                "Termin je uspješno dodan.",
                "Uspješno",
                MessageBoxButton.OK,
                MessageBoxImage.Information);

            DialogResult = true;
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška prilikom dodavanja termina:\n\n{ex.Message}",
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