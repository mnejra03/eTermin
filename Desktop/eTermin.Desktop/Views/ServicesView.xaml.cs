using eTermin.Desktop.Models;
using eTermin.Desktop.Services;
using eTermin.Desktop.Windows;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;

namespace eTermin.Desktop.Views;

public partial class ServicesView : UserControl
{
    private readonly ApiService _apiService;

    private List<ServiceListItem> _services = new();
    private List<ServiceListItem> _filteredServices = new();

    private int _currentPage = 1;

    private int PageSize
    {
        get
        {
            const double rowHeight = 48;

            var availableHeight =
                ServicesDataGrid.ActualHeight;

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
                _filteredServices.Count /
                (double)PageSize));


    public ServicesView(ApiService apiService)
    {
        InitializeComponent();

        _apiService = apiService;

        Loaded += ServicesView_Loaded;
        SizeChanged += ServicesView_SizeChanged;
    }


    // =========================================================
    // LOAD
    // =========================================================

    private async void ServicesView_Loaded(
        object sender,
        RoutedEventArgs e)
    {
        await LoadSalonsAsync();
        await LoadServicesAsync();

        ApplyFilters();
    }


    // =========================================================
    // SALONS
    // =========================================================

    private async Task LoadSalonsAsync()
    {
        try
        {
            var salons =
                await _apiService
                    .GetAsync<List<SalonDto>>(
                        "Salons");

            SalonFilterComboBox.Items.Clear();

            SalonFilterComboBox.Items.Add(
                new SalonFilterItem
                {
                    Id = null,
                    Name = "Svi saloni"
                });

            if (salons != null)
            {
                foreach (var salon in salons)
                {
                    SalonFilterComboBox.Items.Add(
                        new SalonFilterItem
                        {
                            Id = salon.Id,
                            Name = salon.Name
                        });
                }
            }

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
    }


    // =========================================================
    // SERVICES
    // =========================================================

    private async Task LoadServicesAsync()
    {
        try
        {
            var services =
                await _apiService
                    .GetAsync<List<ServiceDto>>(
                        "Services");

            if (services == null)
            {
                _services = new List<ServiceListItem>();
                return;
            }

            var salons =
                await _apiService
                    .GetAsync<List<SalonDto>>(
                        "Salons");

            var salonDictionary =
                salons?
                    .ToDictionary(
                        x => x.Id,
                        x => x.Name)
                ?? new Dictionary<int, string>();


            _services =
                services
                    .Select(service =>
                    {
                        salonDictionary.TryGetValue(
                            service.SalonId,
                            out var salonName);

                        return new ServiceListItem
                        {
                            Id = service.Id,
                            SalonId = service.SalonId,
                            Name = service.Name,
                            Description = service.Description,
                            DurationInMinutes =
                                service.DurationInMinutes,
                            Price = service.Price,
                            IsActive = service.IsActive,
                            SalonName =
                                salonName ?? "Nepoznat salon"
                        };
                    })
                    .ToList();
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


    // =========================================================
    // FILTERI
    // =========================================================

    private void ApplyFilters()
    {
        var searchText =
            SearchTextBox.Text
                .Trim()
                .ToLower();

        var selectedSalon =
            SalonFilterComboBox.SelectedItem
                as SalonFilterItem;


        _filteredServices =
            _services
                .Where(service =>
                    !selectedSalon?.Id.HasValue == true
                    ||
                    service.SalonId ==
                    selectedSalon.Id.Value)
                .Where(service =>
                    string.IsNullOrWhiteSpace(searchText)
                    ||
                    service.Name
                        .ToLower()
                        .Contains(searchText)
                    ||
                    service.Description
                        .ToLower()
                        .Contains(searchText))
                .ToList();


        _currentPage = 1;

        ApplyPagination();
    }


    // =========================================================
    // PAGINATION
    // =========================================================

    private void ApplyPagination()
    {
        var pageSize = PageSize;

        var pageItems =
            _filteredServices
                .Skip(
                    (_currentPage - 1) *
                    pageSize)
                .Take(pageSize)
                .ToList();

        ServicesDataGrid.ItemsSource =
            pageItems;

        UpdatePaginationUI();
    }


    private void UpdatePaginationUI()
    {
        PaginationPanel.Children.Clear();

        if (_filteredServices.Count == 0)
        {
            PaginationInfoText.Text =
                "Nema pronađenih usluga.";

            PaginationPanel.Visibility =
                Visibility.Collapsed;

            return;
        }


        var from =
            ((_currentPage - 1) * PageSize) + 1;

        var to =
            Math.Min(
                _currentPage * PageSize,
                _filteredServices.Count);


        PaginationInfoText.Text =
            $"Prikazano {from}-{to} od {_filteredServices.Count} usluga";


        if (TotalPages <= 1)
        {
            PaginationPanel.Visibility =
                Visibility.Collapsed;

            return;
        }


        PaginationPanel.Visibility =
            Visibility.Visible;


        // PREVIOUS

        var previousButton =
            CreatePaginationButton("‹");

        previousButton.IsEnabled =
            _currentPage > 1;

        previousButton.Click +=
            PreviousPageButton_Click;

        PaginationPanel.Children.Add(
            previousButton);


        // PAGE NUMBERS

        for (int page = 1;
             page <= TotalPages;
             page++)
        {
            var pageButton =
                CreatePaginationButton(
                    page.ToString());

            if (page == _currentPage)
            {
                pageButton.Background =
                    new System.Windows.Media.SolidColorBrush(
                        System.Windows.Media.Color.FromRgb(
                            156,
                            39,
                            176));

                pageButton.Foreground =
                    System.Windows.Media.Brushes.White;
            }

            var selectedPage = page;

            pageButton.Click +=
                (sender, e) =>
                {
                    _currentPage =
                        selectedPage;

                    ApplyPagination();
                };

            PaginationPanel.Children.Add(
                pageButton);
        }


        // NEXT

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
        string text)
    {
        return new Button
        {
            Content = text,
            Width = 32,
            Height = 32,
            Margin = new Thickness(3, 0, 0, 0),
            Background =
                new System.Windows.Media.SolidColorBrush(
                    System.Windows.Media.Color.FromRgb(
                        245,
                        242,
                        247)),
            Foreground =
                new System.Windows.Media.SolidColorBrush(
                    System.Windows.Media.Color.FromRgb(
                        74,
                        65,
                        77)),
            BorderThickness =
                new Thickness(0),
            Cursor =
                System.Windows.Input.Cursors.Hand,
            FontSize = 13
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


    // =========================================================
    // SEARCH
    // =========================================================

    private void SearchTextBox_TextChanged(
        object sender,
        TextChangedEventArgs e)
    {
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
        if (string.IsNullOrWhiteSpace(
                SearchTextBox.Text))
        {
            SearchPlaceholderText.Visibility =
                Visibility.Visible;
        }
    }


    // =========================================================
    // SALON FILTER
    // =========================================================

    private void SalonFilterComboBox_SelectionChanged(
        object sender,
        SelectionChangedEventArgs e)
    {
        if (!IsLoaded)
            return;

        ApplyFilters();
    }


    // =========================================================
    // RESIZE
    // =========================================================

    private void ServicesView_SizeChanged(
        object sender,
        SizeChangedEventArgs e)
    {
        if (!IsLoaded)
            return;

        ApplyPagination();
    }


    // =========================================================
    // ADD
    // =========================================================

    private async void AddServiceButton_Click(
     object sender,
     RoutedEventArgs e)
    {
        var window =
            new AddServiceWindow(_apiService)
            {
                Owner =
                    Window.GetWindow(this)
            };

        var result =
            window.ShowDialog();

        if (result == true)
        {
            await LoadServicesAsync();

            ApplyFilters();
        }
    }


    // =========================================================
    // EDIT
    // =========================================================

    private void EditServiceButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        if (sender is not Button button)
            return;

        if (button.DataContext
            is not ServiceListItem service)
            return;

        MessageBox.Show(
            $"Uređivanje usluge:\n{service.Name}",
            "Usluge",
            MessageBoxButton.OK,
            MessageBoxImage.Information);
    }


    // =========================================================
    // MENU
    // =========================================================

    private void ServiceMenuButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        if (sender is not Button button)
            return;

        if (button.DataContext
            is not ServiceListItem service)
            return;

        var menu =
            new ContextMenu();

        var toggleItem =
            new MenuItem
            {
                Header =
                    service.IsActive
                        ? "Deaktiviraj"
                        : "Aktiviraj"
            };

        toggleItem.Click +=
            async (_, _) =>
            {
                await ToggleServiceStatusAsync(
                    service);
            };

        var deleteItem =
            new MenuItem
            {
                Header = "Obriši"
            };

        deleteItem.Click +=
            async (_, _) =>
            {
                await DeleteServiceAsync(
                    service);
            };

        menu.Items.Add(toggleItem);
        menu.Items.Add(deleteItem);

        menu.PlacementTarget =
            button;

        menu.IsOpen = true;
    }


    // =========================================================
    // TOGGLE STATUS
    // =========================================================

    private async Task ToggleServiceStatusAsync(
        ServiceListItem service)
    {
        try
        {
            var request = new
            {
                SalonId = service.SalonId,
                Name = service.Name,
                Description = service.Description,
                DurationInMinutes =
                    service.DurationInMinutes,
                Price = service.Price,
                IsActive = !service.IsActive
            };

            var success =
                await _apiService.PutAsync(
                    $"Services/{service.Id}",
                    request);

            if (success)
            {
                await LoadServicesAsync();

                ApplyFilters();
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška prilikom promjene statusa:\n{ex.Message}",
                "Greška",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }


    // =========================================================
    // DELETE
    // =========================================================

    private async Task DeleteServiceAsync(
        ServiceListItem service)
    {
        var result =
            MessageBox.Show(
                $"Da li ste sigurni da želite obrisati uslugu \"{service.Name}\"?",
                "Brisanje usluge",
                MessageBoxButton.YesNo,
                MessageBoxImage.Warning);

        if (result != MessageBoxResult.Yes)
            return;


        try
        {
            var success =
                await _apiService.DeleteAsync(
                    $"Services/{service.Id}");

            if (success)
            {
                await LoadServicesAsync();

                ApplyFilters();
            }
            else
            {
                MessageBox.Show(
                    "Usluga nije obrisana.",
                    "Greška",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error);
            }
        }
        catch (Exception)
        {
            MessageBox.Show(
                "Ovu uslugu nije moguće obrisati jer je već korištena u postojećim terminima.\n\n" +
                "Uslugu možete deaktivirati ako je više ne želite koristiti za nove termine.",
                "Nije moguće obrisati uslugu",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);
        }
    }
}


// =============================================================
// DTOs
// =============================================================

public class ServiceDto
{
    public int Id { get; set; }

    public int SalonId { get; set; }

    public string Name { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public int DurationInMinutes { get; set; }

    public decimal Price { get; set; }

    public bool IsActive { get; set; }
}


public class SalonDto
{
    public int Id { get; set; }

    public string Name { get; set; } = string.Empty;
}


// =============================================================
// UI MODELS
// =============================================================

public class ServiceListItem
{
    public int Id { get; set; }

    public int SalonId { get; set; }

    public string Name { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public int DurationInMinutes { get; set; }

    public decimal Price { get; set; }

    public bool IsActive { get; set; }

    public string SalonName { get; set; } = string.Empty;


    public string DurationText =>
        $"{DurationInMinutes} min";


    public string PriceText =>
        $"{Price:0.00} KM";
}
