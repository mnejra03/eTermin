using eTermin.Desktop.Models;
using eTermin.Desktop.Services;
using eTermin.Desktop.Windows;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;

namespace eTermin.Desktop.Views;

public partial class EmployeesView : UserControl
{
    private readonly ApiService _apiService;

    private List<EmployeeListItem> _employees = new();

    private List<EmployeeListItem> _filteredEmployees = new();

    private int _currentPage = 1;

    private int PageSize
    {
        get
        {
            const double rowHeight = 48;

            var availableHeight =
                EmployeesDataGrid.ActualHeight;

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
            _filteredEmployees.Count /
            (double)PageSize));

    private List<Salon> _salons = new();
    private bool _isLoadingSalons;
    private List<Service> _services = new();

    public EmployeesView(ApiService apiService)
    {
        InitializeComponent();

        _apiService = apiService;

        EmployeesDataGrid.ItemsSource = null;
        EmployeesDataGrid.Items.Clear();

        Loaded += EmployeesView_Loaded;
        SizeChanged += EmployeesView_SizeChanged;
    }
    private void EmployeesView_SizeChanged(
    object sender,
    SizeChangedEventArgs e)
    {
        if (!IsLoaded)
            return;

        ApplyPagination();
    }
    private void ApplyPagination()
    {
        if (_currentPage > TotalPages)
            _currentPage = TotalPages;

        var pageSize = PageSize;

        var pagedEmployees =
            _filteredEmployees
                .Skip((_currentPage - 1) * pageSize)
                .Take(pageSize)
                .ToList();

        EmployeesDataGrid.ItemsSource =
            pagedEmployees;

        UpdatePaginationUI();
    }
    private void UpdatePaginationUI()
    {
        PaginationPanel.Children.Clear();

        var totalItems = _filteredEmployees.Count;
        var pageSize = PageSize;

        var start = totalItems == 0
            ? 0
            : ((_currentPage - 1) * pageSize) + 1;

        var end = Math.Min(
            _currentPage * pageSize,
            totalItems);

        PaginationInfoText.Text =
            $"Prikazano {start}–{end} od {totalItems} zaposlenika";

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
  

    private async void EmployeesView_Loaded(object sender, RoutedEventArgs e)
    {
        await LoadSalonsAsync();
        await LoadServicesAsync();
        await LoadEmployeesAsync();
    }

    private async Task LoadServicesAsync()
    {
        try
        {
            var services =
                await _apiService.GetAsync<List<Service>>("Services");

            _services = services ?? new List<Service>();
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

    private async void DeleteEmployeeButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        if (sender is not FrameworkElement element)
            return;

        if (element.DataContext is not EmployeeListItem employee)
            return;

        var result = MessageBox.Show(
            $"Da li želite obrisati zaposlenika \"{employee.FullName}\"?\n\n" +
            "Ova radnja će trajno obrisati zaposlenika.",
            "Brisanje zaposlenika",
            MessageBoxButton.YesNo,
            MessageBoxImage.Warning);

        if (result != MessageBoxResult.Yes)
            return;

        try
        {
            var deleted =
                await _apiService.DeleteAsync(
                    $"Employees/{employee.Id}");

            if (!deleted)
            {
                MessageBox.Show(
                    "Zaposlenika nije moguće obrisati.",
                    "eTermin",
                    MessageBoxButton.OK,
                    MessageBoxImage.Warning);

                return;
            }

            MessageBox.Show(
                "Zaposlenik je uspješno obrisan.",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Information);

            await LoadEmployeesAsync();
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška pri brisanju zaposlenika:\n{ex.Message}",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }
    private async Task LoadSalonsAsync()
    {
        try
        {
            _isLoadingSalons = true;

            var salons =
                await _apiService.GetAsync<List<Salon>>(
                    "Salons");

            _salons =
                salons ?? new List<Salon>();

            var filterItems =
                new List<SalonFilterItem>
                {
                new SalonFilterItem
                {
                    Id = null,
                    Name = "Svi saloni"
                }
                };

            filterItems.AddRange(
                _salons.Select(s => new SalonFilterItem
                {
                    Id = s.Id,
                    Name = s.Name
                }));

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
        finally
        {
            _isLoadingSalons = false;
        }
    }

    private async Task LoadEmployeesAsync()
    {
        try
        {
            var employees =
                await _apiService.GetAsync<List<Employee>>("Employees");

            employees ??= new List<Employee>();

            _employees =
                employees
                    .Select(employee =>
                    {
                        var salon =
                            _salons.FirstOrDefault(s => s.Id == employee.SalonId);

                        var serviceNames = _services
                            .Where(service =>
                                employee.ServiceIds.Contains(service.Id))
                            .Select(service => service.Name)
                            .ToList();

                        return new EmployeeListItem
                        {
                            Id = employee.Id,
                            SalonId = employee.SalonId,
                            FirstName = employee.FirstName,
                            LastName = employee.LastName,
                            Email = employee.Email,
                            PhoneNumber = employee.PhoneNumber,
                            Position = employee.Position,
                            WorkingHours = employee.WorkingHours,
                            IsActive = employee.IsActive,
                            SalonName = salon?.Name ?? "Nepoznat salon",
                            ServicesText = serviceNames.Count > 0
                                ? string.Join(", ", serviceNames)
                                : "—"
                        };
                    })
                    .ToList();

            ApplyFilters();
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška pri učitavanju zaposlenika:\n{ex.Message}",
                "Greška",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private void DetailsEmployeeButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        if (sender is not FrameworkElement element)
            return;

        if (element.DataContext is not EmployeeListItem employee)
            return;

        var window =
            new EmployeeDetailsWindow(employee)
            {
                Owner = Window.GetWindow(this)
            };

        window.ShowDialog();
    }

    private async void EditEmployeeButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        if (sender is not FrameworkElement element)
            return;

        if (element.DataContext is not EmployeeListItem employee)
            return;

        var window =
            new EditEmployeeWindow(
                _apiService,
                employee)
            {
                Owner = Window.GetWindow(this)
            };

        var result = window.ShowDialog();

        if (result == true)
        {
            await LoadEmployeesAsync();
        }
    }


    private void ApplyFilters()
    {
        if (!IsLoaded)
            return;

        IEnumerable<EmployeeListItem> filtered =
            _employees;

        var selectedSalon =
            SalonFilterComboBox.SelectedItem
            as SalonFilterItem;

        if (selectedSalon?.Id.HasValue == true)
        {
            filtered =
                filtered.Where(e =>
                    e.SalonId == selectedSalon.Id.Value);
        }

        var search =
            SearchTextBox.Text
                .Trim()
                .ToLower();

        if (!string.IsNullOrWhiteSpace(search))
        {
            filtered =
                filtered.Where(e =>
                    e.FirstName.ToLower().Contains(search) ||
                    e.LastName.ToLower().Contains(search) ||
                    e.FullName.ToLower().Contains(search) ||
                    e.PhoneNumber.ToLower().Contains(search) ||
                    e.SalonName.ToLower().Contains(search));
        }

        _filteredEmployees =
            filtered.ToList();

        _currentPage = 1;

        ApplyPagination();
    }

    private void SearchTextBox_TextChanged(
        object sender,
        TextChangedEventArgs e)
    {
        SearchPlaceholderText.Visibility =
            string.IsNullOrWhiteSpace(SearchTextBox.Text)
                ? Visibility.Visible
                : Visibility.Collapsed;

        if (!IsLoaded)
            return;

        ApplyFilters();
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


    private void SalonFilterComboBox_SelectionChanged(
    object sender,
    SelectionChangedEventArgs e)
    {
        if (!IsLoaded)
            return;

        if (_isLoadingSalons)
            return;

        ApplyFilters();
    }


    private void AddEmployeeButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        var window =
            new AddEmployeeWindow(_apiService)
            {
                Owner = Window.GetWindow(this)
            };

        window.ShowDialog();

        _ = LoadEmployeesAsync();
    }


    private void EmployeeActionsButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        if (sender is not FrameworkElement element)
            return;

        if (element.DataContext is not EmployeeListItem employee)
            return;

        MessageBox.Show(
            $"Akcije za zaposlenika:\n\n{employee.FullName}",
            "eTermin",
            MessageBoxButton.OK,
            MessageBoxImage.Information);
    }
}

