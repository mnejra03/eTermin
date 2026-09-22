using System.Globalization;
using System.Windows;
using eTermin.Desktop.Models;
using eTermin.Desktop.Services;

namespace eTermin.Desktop.Windows;

public partial class EditAppointmentWindow : Window
{
    private readonly ApiService _apiService;
    private readonly AppointmentListItem _appointment;

    private List<SalonFilterItem> _salons = [];
    private List<ServiceFilterItem> _services = [];
    private List<EmployeeFilterItem> _employees = [];

    public EditAppointmentWindow(
        ApiService apiService,
        AppointmentListItem appointment)
    {
        InitializeComponent();

        _apiService = apiService;
        _appointment = appointment;

        StatusComboBox.ItemsSource = new List<string>
        {
            "Pending",
            "Confirmed",
            "Cancelled",
            "Completed"
        };

        StatusComboBox.SelectedItem = appointment.Status;

        DatePicker.SelectedDate = appointment.StartTime.Date;

        StartTimeTextBox.Text =
            appointment.StartTime.ToString("HH:mm");

        PriceTextBox.Text =
            appointment.Price.ToString(
                "0.00",
                CultureInfo.InvariantCulture);

        Loaded += EditAppointmentWindow_Loaded;
    }

    private async void EditAppointmentWindow_Loaded(
     object sender,
     RoutedEventArgs e)
    {
        await LoadSalonsAsync();

        SalonComboBox.SelectedValue = _appointment.SalonId;

        await LoadServicesAsync(_appointment.SalonId);
        await LoadEmployeesAsync(_appointment.SalonId);

        ServiceComboBox.SelectedValue = _appointment.ServiceId;
        EmployeeComboBox.SelectedValue = _appointment.EmployeeId;
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
                .Where(x => x.SalonId == salonId && x.IsActive)
                .ToList()
                ?? [];

            ServiceComboBox.ItemsSource = _services;
            ServiceComboBox.DisplayMemberPath = "Name";
            ServiceComboBox.SelectedValuePath = "Id";

            ServiceComboBox.SelectedValue =
                _appointment.ServiceId;
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

            EmployeeComboBox.SelectedValue =
                _appointment.EmployeeId;
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

    private async void SaveButton_Click(
        object sender,
        RoutedEventArgs e)
    {
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

        if (!decimal.TryParse(
                PriceTextBox.Text,
                NumberStyles.Number,
                CultureInfo.InvariantCulture,
                out var price))
        {
            MessageBox.Show(
                "Unesite ispravnu cijenu.",
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

        var selectedDate =
            DatePicker.SelectedDate.Value.Date;

        var startDateTime =
            selectedDate + startTime;

        if (ServiceComboBox.SelectedItem is not ServiceFilterItem selectedService)
        {
            MessageBox.Show(
                "Odaberite uslugu.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);

            return;
        }

        var endDateTime =
    startDateTime.AddMinutes(
        selectedService.DurationInMinutes);

        var request = new UpdateAppointmentRequest
        {
            UserId = _appointment.UserId,

            SalonId = salonId,

            EmployeeId = employeeId,

            ServiceId = serviceId,

            StartTime = startDateTime,

            EndTime = endDateTime,

            Status = status,


            CreatedAt = _appointment.CreatedAt
        };

        try
        {
            var success =
                await _apiService.PutAsync(
                    $"Appointments/{_appointment.Id}",
                    request);

            if (!success)
            {
                MessageBox.Show(
                    "Termin nije moguće izmijeniti.",
                    "Greška",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error);

                return;
            }

            MessageBox.Show(
                "Termin je uspješno izmijenjen.",
                "Uspješno",
                MessageBoxButton.OK,
                MessageBoxImage.Information);

            DialogResult = true;
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška prilikom izmjene termina:\n\n{ex.Message}",
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


    private async void SalonComboBox_SelectionChanged(
    object sender,
    System.Windows.Controls.SelectionChangedEventArgs e)
    {
        if (SalonComboBox.SelectedValue is not int salonId)
            return;

        await LoadServicesAsync(salonId);
        await LoadEmployeesAsync(salonId);
    }

    private void ServiceComboBox_SelectionChanged(
    object sender,
    System.Windows.Controls.SelectionChangedEventArgs e)
    {
        if (ServiceComboBox.SelectedItem is not ServiceFilterItem service)
            return;

        PriceTextBox.Text =
            service.Price.ToString("0.00");
    }
}