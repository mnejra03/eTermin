using eTermin.Desktop.Services;
using Microsoft.Win32;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPdfInfrastructure = QuestPDF.Infrastructure;
using System.Reflection.Metadata;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Shapes;
using System.Windows.Threading;
using ClosedXML.Excel;

namespace eTermin.Desktop.Views;

public partial class StatisticsView : UserControl
{
    private readonly ApiService _apiService;

    private DashboardStatisticsDto? _currentStatistics;

    public StatisticsView(ApiService apiService)
    {
        InitializeComponent();

        _apiService = apiService;

        Loaded += StatisticsView_Loaded;
    }

    private async void StatisticsView_Loaded(
        object sender,
        RoutedEventArgs e)
    {
        LoadFilters();

        await LoadStatisticsAsync();
    }

    private void LoadFilters()
    {
        PeriodComboBox.Items.Clear();

        PeriodComboBox.Items.Add("Dnevni");
        PeriodComboBox.Items.Add("Sedmični");
        PeriodComboBox.Items.Add("Mjesečni");

        PeriodComboBox.SelectedIndex = 2;


        StatusFilterComboBox.Items.Clear();

        StatusFilterComboBox.Items.Add("All statuses");
        StatusFilterComboBox.Items.Add("Pending");
        StatusFilterComboBox.Items.Add("Confirmed");
        StatusFilterComboBox.Items.Add("Completed");
        StatusFilterComboBox.Items.Add("Cancelled");

        StatusFilterComboBox.SelectedIndex = 0;


        PeriodComboBox.SelectionChanged +=
            PeriodComboBox_SelectionChanged;

        StatusFilterComboBox.SelectionChanged +=
            StatusFilterComboBox_SelectionChanged;
    }

    private async void PeriodComboBox_SelectionChanged(
    object sender,
    SelectionChangedEventArgs e)
    {
        if (!IsLoaded)
            return;

        await LoadStatisticsAsync();
    }

    private async void StatusFilterComboBox_SelectionChanged(
    object sender,
    SelectionChangedEventArgs e)
    {
        if (!IsLoaded)
            return;

        await LoadStatisticsAsync();
    }

    private async Task LoadStatisticsAsync()
    {
        try
        {
            var today = DateTime.Today;

            DateTime from;
            DateTime to;


            switch (PeriodComboBox.SelectedItem?.ToString())
            {
                case "Dnevni":

                    from = today;
                    to = today.AddDays(1);

                    break;


                case "Sedmični":

                    var difference =
                        ((int)today.DayOfWeek + 6) % 7;

                    from =
                        today.AddDays(-difference);

                    to =
                        from.AddDays(7);

                    break;


                case "Mjesečni":

                    from =
                        new DateTime(
                            today.Year,
                            today.Month,
                            1);

                    to =
                        from.AddMonths(1);

                    break;


                default:

                    from =
                        today;

                    to =
                        today.AddDays(1);

                    break;
            }


            var status =
    StatusFilterComboBox.SelectedItem?.ToString()
    ?? "All statuses";

            var endpoint =
                $"Statistics/dashboard" +
                $"?from={from:yyyy-MM-dd}" +
                $"&to={to:yyyy-MM-dd}" +
                $"&status={Uri.EscapeDataString(status)}";




            var statistics =
                await _apiService
                    .GetAsync<DashboardStatisticsDto>(
                        endpoint);


            if (statistics == null)
                return;

            _currentStatistics = statistics;


            AppointmentsSummaryText.Text =
    statistics.TotalAppointments.ToString();

            RevenueSummaryText.Text =
                $"{statistics.TotalRevenue:0.00} KM";

            DrawReservationsChart(
     statistics.ReservationsByDay);

            DrawPopularServicesChart(
                statistics.ReservationsByService);

            DrawAppointmentStatusChart(
                statistics.ReservationsByStatus);
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška prilikom učitavanja statistike:\n{ex.Message}",
                "Greška",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private void ExportPdfButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        try
        {
            if (_currentStatistics == null)
            {
                MessageBox.Show(
                    "Statistika još nije učitana.",
                    "eTermin",
                    MessageBoxButton.OK,
                    MessageBoxImage.Warning);

                return;
            }

            var saveDialog = new SaveFileDialog
            {
                Title = "Sačuvaj statistički izvještaj",
                Filter = "PDF dokument (*.pdf)|*.pdf",
                FileName =
                    $"eTermin_Statistika_{DateTime.Now:yyyyMMdd_HHmm}.pdf"
            };

            if (saveDialog.ShowDialog() != true)
                return;

            GenerateStatisticsPdf(
                saveDialog.FileName,
                _currentStatistics);

            MessageBox.Show(
                "PDF izvještaj je uspješno kreiran.",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Information);
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška prilikom kreiranja PDF-a:\n{ex.Message}",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }
    private void GenerateStatisticsPdf(
    string filePath,
    DashboardStatisticsDto statistics)
    {
        QuestPDF.Settings.License =
    QuestPdfInfrastructure.LicenseType.Community;

        var period =
            PeriodComboBox.SelectedItem?.ToString()
            ?? "Nepoznato";

        var status =
            StatusFilterComboBox.SelectedItem?.ToString()
            ?? "All statuses";

        QuestPDF.Fluent.Document
    .Create(document =>
    {
                document.Page(page =>
                {
                    page.Size(PageSizes.A4);
                    page.Margin(40);

                    page.DefaultTextStyle(
                        x => x.FontSize(10));

                    page.Header()
                        .Column(column =>
                        {
                            column.Item()
                                .Text("eTermin")
                                .FontSize(24)
                                .Bold()
                                .FontColor(
                                    "#6D4C73");

                            column.Item()
                                .Text(
                                    "Statistički izvještaj")
                                .FontSize(16)
                                .Bold();

                            column.Item()
                                .Text(
                                    $"Period: {period}  |  " +
                                    $"Status: {GetPdfStatusName(status)}")
                                .FontSize(10)
                                .FontColor(
                                    "#777777");
                        });

                    page.Content()
                        .PaddingTop(25)
                        .Column(column =>
                        {
                            // KPI
                            column.Item()
                                .Row(row =>
                                {
                                    row.RelativeItem()
                                        .Border(1)
                                        .BorderColor("#EAE5ED")
                                        .Padding(15)
                                        .Column(card =>
                                        {
                                            card.Item()
                                                .Text("Broj termina")
                                                .FontSize(11)
                                                .FontColor("#777777");

                                            card.Item()
                                                .Text(
                                                    statistics
                                                        .TotalAppointments
                                                        .ToString())
                                                .FontSize(24)
                                                .Bold()
                                                .FontColor("#6D4C73");
                                        });

                                    row.ConstantItem(15);

                                    row.RelativeItem()
                                        .Border(1)
                                        .BorderColor("#EAE5ED")
                                        .Padding(15)
                                        .Column(card =>
                                        {
                                            card.Item()
                                                .Text("Prihod")
                                                .FontSize(11)
                                                .FontColor("#777777");

                                            card.Item()
                                                .Text(
                                                    $"{statistics.TotalRevenue:0.00} KM")
                                                .FontSize(24)
                                                .Bold()
                                                .FontColor("#6D4C73");
                                        });
                                });

                            // Popularne usluge
                            column.Item()
                                .PaddingTop(25)
                                .Text("Popularnost usluga")
                                .FontSize(15)
                                .Bold()
                                .FontColor("#2D1B36");

                            column.Item()
                                .PaddingTop(10)
                                .Table(table =>
                                {
                                    table.ColumnsDefinition(
                                        columns =>
                                        {
                                            columns.RelativeColumn();
                                            columns.ConstantColumn(80);
                                        });

                                    table.Header(header =>
                                    {
                                        header.Cell()
                                            .Background("#F7F4F8")
                                            .Padding(8)
                                            .Text("Usluga")
                                            .Bold();

                                        header.Cell()
                                            .Background("#F7F4F8")
                                            .Padding(8)
                                            .Text("Broj")
                                            .Bold();
                                    });

                                    foreach (
                                        var service
                                        in statistics.ReservationsByService)
                                    {
                                        table.Cell()
                                            .Padding(8)
                                            .Text(
                                                service.ServiceName);

                                        table.Cell()
                                            .Padding(8)
                                            .Text(
                                                service.Count
                                                    .ToString());
                                    }
                                });

                            // Statusi
                            column.Item()
                                .PaddingTop(25)
                                .Text("Status termina")
                                .FontSize(15)
                                .Bold()
                                .FontColor("#2D1B36");

                            column.Item()
                                .PaddingTop(10)
                                .Table(table =>
                                {
                                    table.ColumnsDefinition(
                                        columns =>
                                        {
                                            columns.RelativeColumn();
                                            columns.ConstantColumn(80);
                                        });

                                    table.Header(header =>
                                    {
                                        header.Cell()
                                            .Background("#F7F4F8")
                                            .Padding(8)
                                            .Text("Status")
                                            .Bold();

                                        header.Cell()
                                            .Background("#F7F4F8")
                                            .Padding(8)
                                            .Text("Broj")
                                            .Bold();
                                    });

                                    foreach (
                                        var item
                                        in statistics.ReservationsByStatus)
                                    {
                                        table.Cell()
                                            .Padding(8)
                                            .Text(
                                                GetPdfStatusName(
                                                    item.Status));

                                        table.Cell()
                                            .Padding(8)
                                            .Text(
                                                item.Count
                                                    .ToString());
                                    }
                                });

                            // Dnevna raspodjela
                            column.Item()
                                .PaddingTop(25)
                                .Text("Broj termina po danima")
                                .FontSize(15)
                                .Bold()
                                .FontColor("#2D1B36");

                            column.Item()
                                .PaddingTop(10)
                                .Table(table =>
                                {
                                    table.ColumnsDefinition(
                                        columns =>
                                        {
                                            columns.RelativeColumn();
                                            columns.ConstantColumn(80);
                                        });

                                    table.Header(header =>
                                    {
                                        header.Cell()
                                            .Background("#F7F4F8")
                                            .Padding(8)
                                            .Text("Datum")
                                            .Bold();

                                        header.Cell()
                                            .Background("#F7F4F8")
                                            .Padding(8)
                                            .Text("Broj")
                                            .Bold();
                                    });

                                    foreach (
                                        var item
                                        in statistics.ReservationsByDay)
                                    {
                                        table.Cell()
                                            .Padding(8)
                                            .Text(
                                                item.Date
                                                    .ToString("dd.MM.yyyy."));

                                        table.Cell()
                                            .Padding(8)
                                            .Text(
                                                item.Count
                                                    .ToString());
                                    }
                                });
                        });

                    page.Footer()
                        .AlignCenter()
                        .Text(text =>
                        {
                            text.Span(
                                "eTermin · Statistički izvještaj · ");

                            text.Span(
                                DateTime.Now
                                    .ToString("dd.MM.yyyy."));
                        });
                });
            })
            .GeneratePdf(filePath);
    }

    private string GetPdfStatusName(string status)
    {
        return status switch
        {
            "All statuses" => "Svi statusi",
            "Pending" => "Na čekanju",
            "Confirmed" => "Potvrđeno",
            "Completed" => "Završeno",
            "Cancelled" => "Otkazano",
            _ => status
        };
    }

    private void DrawReservationsChart(
    List<DailyReservationDto> reservations)
    {
        ReservationsChartGrid.Children.Clear();

        if (reservations == null || reservations.Count == 0)
        {
            ReservationsChartGrid.Children.Add(
                new TextBlock
                {
                    Text = "Nema podataka za odabrani period.",
                    FontSize = 14,
                    Foreground = new SolidColorBrush(
                        Color.FromRgb(119, 119, 119)),
                    HorizontalAlignment = HorizontalAlignment.Center,
                    VerticalAlignment = VerticalAlignment.Center
                });

            return;
        }

        var canvas = new Canvas
        {
            HorizontalAlignment = HorizontalAlignment.Stretch,
            VerticalAlignment = VerticalAlignment.Stretch
        };

        ReservationsChartGrid.Children.Add(canvas);

        Dispatcher.BeginInvoke(
            new Action(() =>
            {
                var period =
                    PeriodComboBox.SelectedItem?.ToString();

                if (period == "Dnevni")
                {
                    DrawDailyReservationChart(
                        canvas,
                        reservations);
                }
                else if (period == "Sedmični")
                {
                    DrawWeeklyReservationChart(
                        canvas,
                        reservations);
                }
                else
                {
                    DrawMonthlyReservationChart(
                        canvas,
                        reservations);
                }
            }),
            DispatcherPriority.Loaded);
    }

    private void DrawMonthlyReservationChart(
    Canvas canvas,
    List<DailyReservationDto> reservations)
    {
        canvas.Children.Clear();

        var width = ReservationsChartGrid.ActualWidth;
        var height = ReservationsChartGrid.ActualHeight;

        if (width <= 0 || height <= 0)
            return;

        const double leftMargin = 45;
        const double rightMargin = 20;
        const double topMargin = 20;
        const double bottomMargin = 40;

        var chartWidth =
            width - leftMargin - rightMargin;

        var chartHeight =
            height - topMargin - bottomMargin;

        var maxValue =
            Math.Max(
                reservations.Max(x => x.Count),
                1);

        // Mreža
        for (int i = 0; i <= maxValue; i++)
        {
            var y =
                topMargin +
                chartHeight -
                i * chartHeight / maxValue;

            var line = new Line
            {
                X1 = leftMargin,
                Y1 = y,
                X2 = width - rightMargin,
                Y2 = y,
                Stroke = new SolidColorBrush(
                    Color.FromRgb(235, 230, 237)),
                StrokeThickness = 1
            };

            canvas.Children.Add(line);

            var label = new TextBlock
            {
                Text = i.ToString(),
                FontSize = 11,
                Foreground = new SolidColorBrush(
                    Color.FromRgb(119, 119, 119)),
                Width = 30,
                TextAlignment = TextAlignment.Right
            };

            Canvas.SetLeft(label, 5);
            Canvas.SetTop(label, y - 8);

            canvas.Children.Add(label);
        }

        // Tačke
        var points = new List<Point>();

        for (int i = 0; i < reservations.Count; i++)
        {
            var item = reservations[i];

            var x =
                reservations.Count == 1
                    ? leftMargin + chartWidth / 2
                    : leftMargin +
                      i *
                      chartWidth /
                      (reservations.Count - 1);

            var y =
                topMargin +
                chartHeight -
                item.Count *
                chartHeight /
                maxValue;

            points.Add(new Point(x, y));
        }

        // Linija
        for (int i = 0; i < points.Count - 1; i++)
        {
            var line = new Line
            {
                X1 = points[i].X,
                Y1 = points[i].Y,
                X2 = points[i + 1].X,
                Y2 = points[i + 1].Y,
                Stroke = new SolidColorBrush(
                    Color.FromRgb(109, 76, 115)),
                StrokeThickness = 2
            };

            canvas.Children.Add(line);
        }

        // Tačke
        for (int i = 0; i < points.Count; i++)
        {
            var point = points[i];

            var circle = new Ellipse
            {
                Width = 7,
                Height = 7,
                Fill = new SolidColorBrush(
                    Color.FromRgb(109, 76, 115))
            };

            Canvas.SetLeft(
                circle,
                point.X - 3.5);

            Canvas.SetTop(
                circle,
                point.Y - 3.5);

            canvas.Children.Add(circle);

            // Prikaži samo svaki 5. dan
            // i zadnji dan
            bool showDate =
                i == 0 ||
                i == reservations.Count - 1 ||
                reservations[i].Date.Day % 5 == 0;

            if (showDate)
            {
                var dateText = new TextBlock
                {
                    Text =
                        reservations[i]
                            .Date
                            .ToString("dd.MM."),

                    FontSize = 10,

                    Foreground =
                        new SolidColorBrush(
                            Color.FromRgb(
                                119,
                                119,
                                119)),

                    Width = 45,

                    TextAlignment =
                        TextAlignment.Center
                };

                Canvas.SetLeft(
                    dateText,
                    point.X - 22);

                Canvas.SetTop(
                    dateText,
                    height - 28);

                canvas.Children.Add(
                    dateText);
            }
        }
    }


    private void DrawAppointmentStatusChart(
    List<ReservationStatusDto> statuses)
    {
        AppointmentStatusChartGrid.Children.Clear();

        if (statuses == null || statuses.Count == 0)
        {
            AppointmentStatusChartGrid.Children.Add(
                new TextBlock
                {
                    Text = "Nema podataka za odabrani period.",
                    FontSize = 13,
                    Foreground = new SolidColorBrush(
                        Color.FromRgb(119, 119, 119)),
                    HorizontalAlignment =
                        HorizontalAlignment.Center,
                    VerticalAlignment =
                        VerticalAlignment.Center
                });

            return;
        }

        var total =
            statuses.Sum(x => x.Count);

        if (total == 0)
        {
            AppointmentStatusChartGrid.Children.Add(
                new TextBlock
                {
                    Text = "Nema termina.",
                    FontSize = 13,
                    Foreground = new SolidColorBrush(
                        Color.FromRgb(119, 119, 119)),
                    HorizontalAlignment =
                        HorizontalAlignment.Center,
                    VerticalAlignment =
                        VerticalAlignment.Center
                });

            return;
        }

        var container = new StackPanel
        {
            Margin = new Thickness(5, 10, 5, 5)
        };

        foreach (var item in statuses)
        {
            var row = new Grid
            {
                Margin = new Thickness(0, 0, 0, 12)
            };

            row.ColumnDefinitions.Add(
                new ColumnDefinition
                {
                    Width = new GridLength(105)
                });

            row.ColumnDefinitions.Add(
                new ColumnDefinition
                {
                    Width = new GridLength(1, GridUnitType.Star)
                });

            row.ColumnDefinitions.Add(
                new ColumnDefinition
                {
                    Width = new GridLength(30)
                });

            // -----------------------------
            // NAZIV STATUSA
            // -----------------------------

            var nameText = new TextBlock
            {
                Text = GetStatusName(item.Status),
                FontSize = 12,
                Foreground = new SolidColorBrush(
                    Color.FromRgb(70, 60, 75)),
                VerticalAlignment =
                    VerticalAlignment.Center
            };

            Grid.SetColumn(nameText, 0);

            row.Children.Add(nameText);

            // -----------------------------
            // BAR
            // -----------------------------

            var barBackground = new Border
            {
                Height = 10,
                Background = new SolidColorBrush(
                    Color.FromRgb(239, 235, 241)),
                CornerRadius = new CornerRadius(5),
                Margin = new Thickness(5, 0, 5, 0),
                VerticalAlignment =
                    VerticalAlignment.Center
            };

            Grid.SetColumn(
                barBackground,
                1);

            var percentage =
                (double)item.Count / total;

            var bar = new Border
            {
                Height = 10,
                Width = 0,
                Background = GetStatusBrush(item.Status),
                CornerRadius = new CornerRadius(5),
                HorizontalAlignment =
                    HorizontalAlignment.Left
            };

            // Animacija nije potrebna — samo širina
            barBackground.Child = bar;

            bar.Width = Math.Max(
                10,
                percentage * 130);

            row.Children.Add(barBackground);

            // -----------------------------
            // BROJ
            // -----------------------------

            var countText = new TextBlock
            {
                Text = item.Count.ToString(),
                FontSize = 12,
                FontWeight = FontWeights.SemiBold,
                Foreground = new SolidColorBrush(
                    Color.FromRgb(109, 76, 115)),
                HorizontalAlignment =
                    HorizontalAlignment.Right,
                VerticalAlignment =
                    VerticalAlignment.Center
            };

            Grid.SetColumn(
                countText,
                2);

            row.Children.Add(countText);

            container.Children.Add(row);
        }

        AppointmentStatusChartGrid.Children.Add(
            container);
    }

    private string GetStatusName(string status)
    {
        return status switch
        {
            "Pending" => "Na čekanju",
            "Confirmed" => "Potvrđeno",
            "Completed" => "Završeno",
            "Cancelled" => "Otkazano",
            _ => status
        };
    }

    private Brush GetStatusBrush(string status)
    {
        return status switch
        {
            "Pending" =>
                new SolidColorBrush(
                    Color.FromRgb(180, 140, 190)),

            "Confirmed" =>
                new SolidColorBrush(
                    Color.FromRgb(150, 100, 165)),

            "Completed" =>
                new SolidColorBrush(
                    Color.FromRgb(109, 76, 115)),

            "Cancelled" =>
                new SolidColorBrush(
                    Color.FromRgb(200, 180, 205)),

            _ =>
                new SolidColorBrush(
                    Color.FromRgb(170, 150, 175))
        };
    }

    private void DrawDailyReservationChart(
    Canvas canvas,
    List<DailyReservationDto> reservations)
    {
        canvas.Children.Clear();

        var width = ReservationsChartGrid.ActualWidth;
        var height = ReservationsChartGrid.ActualHeight;

        if (width <= 0 || height <= 0)
            return;

        const double leftMargin = 50;
        const double rightMargin = 30;
        const double topMargin = 25;
        const double bottomMargin = 45;

        var chartWidth =
            width - leftMargin - rightMargin;

        var chartHeight =
            height - topMargin - bottomMargin;

        var item = reservations.First();

        var maxValue = Math.Max(item.Count, 1);

        // Y osa
        for (int i = 0; i <= maxValue; i++)
        {
            var y =
                topMargin +
                chartHeight -
                i * chartHeight / maxValue;

            var line = new Line
            {
                X1 = leftMargin,
                Y1 = y,
                X2 = width - rightMargin,
                Y2 = y,
                Stroke = new SolidColorBrush(
                    Color.FromRgb(235, 230, 237)),
                StrokeThickness = 1
            };

            canvas.Children.Add(line);

            var label = new TextBlock
            {
                Text = i.ToString(),
                FontSize = 11,
                Foreground = new SolidColorBrush(
                    Color.FromRgb(119, 119, 119)),
                Width = 30,
                TextAlignment = TextAlignment.Right
            };

            Canvas.SetLeft(label, 5);
            Canvas.SetTop(label, y - 8);

            canvas.Children.Add(label);
        }

        // Stupac
        const double barWidth = 80;

        var barHeight =
            item.Count == 0
                ? 0
                : item.Count * chartHeight / maxValue;

        var barX =
            leftMargin +
            (chartWidth - barWidth) / 2;

        var barY =
            topMargin +
            chartHeight -
            barHeight;

        var bar = new Rectangle
        {
            Width = barWidth,
            Height = Math.Max(barHeight, 2),
            Fill = new SolidColorBrush(
                Color.FromRgb(109, 76, 115))
        };

        Canvas.SetLeft(bar, barX);
        Canvas.SetTop(bar, barY);

        canvas.Children.Add(bar);

        // Broj iznad stupca
        var valueText = new TextBlock
        {
            Text = item.Count.ToString(),
            FontSize = 14,
            FontWeight = FontWeights.SemiBold,
            Foreground = new SolidColorBrush(
                Color.FromRgb(109, 76, 115)),
            Width = barWidth,
            TextAlignment = TextAlignment.Center
        };

        Canvas.SetLeft(valueText, barX);
        Canvas.SetTop(
            valueText,
            Math.Max(barY - 25, 0));

        canvas.Children.Add(valueText);

        // Datum
        var dateText = new TextBlock
        {
            Text = item.Date.ToString("dd.MM."),
            FontSize = 11,
            Foreground = new SolidColorBrush(
                Color.FromRgb(119, 119, 119)),
            Width = 80,
            TextAlignment = TextAlignment.Center
        };

        Canvas.SetLeft(
            dateText,
            barX);

        Canvas.SetTop(
            dateText,
            height - 30);

        canvas.Children.Add(dateText);
    }

    private void DrawWeeklyReservationChart(
    Canvas canvas,
    List<DailyReservationDto> reservations)
    {
        canvas.Children.Clear();

        var width = ReservationsChartGrid.ActualWidth;
        var height = ReservationsChartGrid.ActualHeight;

        if (width <= 0 || height <= 0)
            return;

        const double leftMargin = 45;
        const double rightMargin = 20;
        const double topMargin = 20;
        const double bottomMargin = 45;

        var chartWidth =
            width - leftMargin - rightMargin;

        var chartHeight =
            height - topMargin - bottomMargin;

        var maxValue =
            Math.Max(
                reservations.Max(x => x.Count),
                1);

        // Y osa
        for (int i = 0; i <= maxValue; i++)
        {
            var y =
                topMargin +
                chartHeight -
                i * chartHeight / maxValue;

            var line = new Line
            {
                X1 = leftMargin,
                Y1 = y,
                X2 = width - rightMargin,
                Y2 = y,
                Stroke = new SolidColorBrush(
                    Color.FromRgb(235, 230, 237)),
                StrokeThickness = 1
            };

            canvas.Children.Add(line);

            var label = new TextBlock
            {
                Text = i.ToString(),
                FontSize = 11,
                Foreground = new SolidColorBrush(
                    Color.FromRgb(119, 119, 119)),
                Width = 30,
                TextAlignment = TextAlignment.Right
            };

            Canvas.SetLeft(label, 5);
            Canvas.SetTop(label, y - 8);

            canvas.Children.Add(label);
        }

        var count = reservations.Count;

        var slotWidth =
            chartWidth / count;

        var barWidth =
            Math.Min(slotWidth * 0.55, 55);

        for (int i = 0; i < count; i++)
        {
            var item = reservations[i];

            var barHeight =
                item.Count == 0
                    ? 0
                    : item.Count *
                      chartHeight /
                      maxValue;

            var x =
                leftMargin +
                i * slotWidth +
                (slotWidth - barWidth) / 2;

            var y =
                topMargin +
                chartHeight -
                barHeight;

            var bar = new Rectangle
            {
                Width = barWidth,
                Height = Math.Max(barHeight, 2),
                Fill = new SolidColorBrush(
                    Color.FromRgb(109, 76, 115))
            };

            Canvas.SetLeft(bar, x);
            Canvas.SetTop(bar, y);

            canvas.Children.Add(bar);

            // Broj
            var valueText = new TextBlock
            {
                Text = item.Count.ToString(),
                FontSize = 11,
                FontWeight = FontWeights.SemiBold,
                Foreground = new SolidColorBrush(
                    Color.FromRgb(109, 76, 115)),
                Width = barWidth,
                TextAlignment = TextAlignment.Center
            };

            Canvas.SetLeft(valueText, x);
            Canvas.SetTop(
                valueText,
                Math.Max(y - 22, 0));

            canvas.Children.Add(valueText);

            // Dan
            var dateText = new TextBlock
            {
                Text = item.Date.ToString("ddd"),
                FontSize = 10,
                Foreground = new SolidColorBrush(
                    Color.FromRgb(119, 119, 119)),
                Width = slotWidth,
                TextAlignment = TextAlignment.Center
            };

            Canvas.SetLeft(
                dateText,
                leftMargin + i * slotWidth);

            Canvas.SetTop(
                dateText,
                height - 30);

            canvas.Children.Add(dateText);
        }
    }

    private void DrawReservationLines(
    Canvas canvas,
    List<DailyReservationDto> reservations)
    {
        canvas.Children.Clear();

        var width =
            ReservationsChartGrid.ActualWidth;

        var height =
            ReservationsChartGrid.ActualHeight;

        if (width <= 0 || height <= 0)
            return;

        const double leftMargin = 45;
        const double rightMargin = 20;
        const double topMargin = 20;
        const double bottomMargin = 40;

        var chartWidth =
            width -
            leftMargin -
            rightMargin;

        var chartHeight =
            height -
            topMargin -
            bottomMargin;

        if (chartWidth <= 0 ||
            chartHeight <= 0)
            return;

        var maxValue =
            Math.Max(
                reservations.Max(x => x.Count),
                1);

        // ==========================================
        // Y OSA I MREŽA
        // ==========================================

        for (var i = 0; i <= maxValue; i++)
        {
            var y =
                topMargin +
                chartHeight -
                (i * chartHeight / maxValue);

            var gridLine = new Line
            {
                X1 = leftMargin,
                Y1 = y,

                X2 = width - rightMargin,
                Y2 = y,

                Stroke =
                    new SolidColorBrush(
                        Color.FromRgb(235, 230, 237)),

                StrokeThickness = 1
            };

            canvas.Children.Add(gridLine);

            var valueText =
                new TextBlock
                {
                    Text = i.ToString(),

                    FontSize = 11,

                    Foreground =
                        new SolidColorBrush(
                            Color.FromRgb(
                                119,
                                119,
                                119)),

                    Width = 30,

                    TextAlignment =
                        TextAlignment.Right
                };

            Canvas.SetLeft(
                valueText,
                5);

            Canvas.SetTop(
                valueText,
                y - 8);

            canvas.Children.Add(valueText);
        }

        // ==========================================
        // TAČKE
        // ==========================================

        var points =
            new List<Point>();

        for (var i = 0;
             i < reservations.Count;
             i++)
        {
            var item =
                reservations[i];

            double x;

            if (reservations.Count == 1)
            {
                x =
                    leftMargin +
                    chartWidth / 2;
            }
            else
            {
                x =
                    leftMargin +
                    i *
                    chartWidth /
                    (reservations.Count - 1);
            }

            var y =
                topMargin +
                chartHeight -
                item.Count *
                chartHeight /
                maxValue;

            points.Add(
                new Point(x, y));
        }

        // ==========================================
        // LINIJA
        // ==========================================

        for (var i = 0;
             i < points.Count - 1;
             i++)
        {
            var line =
                new Line
                {
                    X1 = points[i].X,
                    Y1 = points[i].Y,

                    X2 = points[i + 1].X,
                    Y2 = points[i + 1].Y,

                    Stroke =
                        new SolidColorBrush(
                            Color.FromRgb(
                                109,
                                76,
                                115)),

                    StrokeThickness = 3
                };

            canvas.Children.Add(line);
        }

        // ==========================================
        // TAČKE I DATUMI
        // ==========================================

        for (var i = 0;
             i < points.Count;
             i++)
        {
            var point =
                points[i];

            // TAČKA
            var ellipse =
                new Ellipse
                {
                    Width = 9,
                    Height = 9,

                    Fill =
                        new SolidColorBrush(
                            Color.FromRgb(
                                109,
                                76,
                                115))
                };

            Canvas.SetLeft(
                ellipse,
                point.X - 4.5);

            Canvas.SetTop(
                ellipse,
                point.Y - 4.5);

            canvas.Children.Add(
                ellipse);


            // DATUM
            var dateText =
                new TextBlock
                {
                    Text =
                        reservations[i]
                            .Date
                            .ToString("dd.MM."),

                    FontSize = 10,

                    Foreground =
                        new SolidColorBrush(
                            Color.FromRgb(
                                119,
                                119,
                                119)),

                    Width = 50,

                    TextAlignment =
                        TextAlignment.Center
                };

            Canvas.SetLeft(
                dateText,
                point.X - 25);

            Canvas.SetTop(
                dateText,
                height - 28);

            canvas.Children.Add(
                dateText);
        }
    }

    private void DrawPopularServicesChart(
    List<ServiceReservationDto> services)
    {
        PopularServicesChartGrid.Children.Clear();

        if (services == null || services.Count == 0)
        {
            PopularServicesChartGrid.Children.Add(
                new TextBlock
                {
                    Text = "Nema podataka.",
                    FontSize = 13,
                    Foreground = new SolidColorBrush(
                        Color.FromRgb(119, 119, 119)),
                    HorizontalAlignment =
                        HorizontalAlignment.Center,
                    VerticalAlignment =
                        VerticalAlignment.Center
                });

            return;
        }

        var chartGrid = new Grid();

        chartGrid.ColumnDefinitions.Add(
            new ColumnDefinition
            {
                Width = new GridLength(1, GridUnitType.Star)
            });

        chartGrid.ColumnDefinitions.Add(
            new ColumnDefinition
            {
                Width = GridLength.Auto
            });

        var canvas = new Canvas
        {
            Width = 150,
            Height = 150
        };

        Grid.SetColumn(canvas, 0);

        chartGrid.Children.Add(canvas);

        var legend = new StackPanel
        {
            Margin = new Thickness(10, 0, 0, 0),
            VerticalAlignment = VerticalAlignment.Center
        };

        Grid.SetColumn(legend, 1);

        chartGrid.Children.Add(legend);

        PopularServicesChartGrid.Children.Add(chartGrid);

        DrawPieChart(
            canvas,
            legend,
            services.Select(x =>
                new PieChartItem
                {
                    Name = x.ServiceName,
                    Value = x.Count
                }).ToList());
    }

    private void ExportExcelButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        try
        {
            if (_currentStatistics == null)
            {
                MessageBox.Show(
                    "Statistika još nije učitana.",
                    "eTermin",
                    MessageBoxButton.OK,
                    MessageBoxImage.Warning);

                return;
            }

            var saveDialog = new SaveFileDialog
            {
                Title = "Sačuvaj Excel izvještaj",
                Filter = "Excel dokument (*.xlsx)|*.xlsx",
                FileName =
                    $"eTermin_Statistika_{DateTime.Now:yyyyMMdd_HHmm}.xlsx"
            };

            if (saveDialog.ShowDialog() != true)
                return;

            GenerateStatisticsExcel(
                saveDialog.FileName,
                _currentStatistics);

            MessageBox.Show(
                "Excel izvještaj je uspješno kreiran.",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Information);
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška prilikom kreiranja Excel izvještaja:\n{ex.Message}",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private void GenerateStatisticsExcel(
    string filePath,
    DashboardStatisticsDto statistics)
    {
        var period =
            PeriodComboBox.SelectedItem?.ToString()
            ?? "Nepoznato";

        var status =
            StatusFilterComboBox.SelectedItem?.ToString()
            ?? "All statuses";

        using var workbook = new XLWorkbook();

        var worksheet =
            workbook.Worksheets.Add("Statistika");

        // ==========================================
        // NASLOV
        // ==========================================

        worksheet.Cell("A1")
            .Value = "eTermin - Statistički izvještaj";

        worksheet.Range("A1:B1")
            .Merge();

        worksheet.Cell("A1")
            .Style.Font.Bold = true;

        worksheet.Cell("A1")
            .Style.Font.FontSize = 18;

        worksheet.Cell("A1")
            .Style.Font.FontColor =
                XLColor.FromHtml("#6D4C73");

        // ==========================================
        // FILTERI
        // ==========================================

        worksheet.Cell("A3")
            .Value = "Period";

        worksheet.Cell("B3")
            .Value = period;

        worksheet.Cell("A4")
            .Value = "Status";

        worksheet.Cell("B4")
            .Value = GetPdfStatusName(status);

        // ==========================================
        // KPI
        // ==========================================

        worksheet.Cell("A6")
            .Value = "Broj termina";

        worksheet.Cell("B6")
            .Value = statistics.TotalAppointments;

        worksheet.Cell("A7")
            .Value = "Prihod";

        worksheet.Cell("B7")
            .Value = statistics.TotalRevenue;

        worksheet.Cell("B7")
            .Style.NumberFormat.Format = "0.00";

        // ==========================================
        // POPULARNOST USLUGA
        // ==========================================

        worksheet.Cell("A10")
            .Value = "Popularnost usluga";

        worksheet.Cell("A10")
            .Style.Font.Bold = true;

        worksheet.Cell("A11")
            .Value = "Usluga";

        worksheet.Cell("B11")
            .Value = "Broj termina";

        StyleExcelHeader(
            worksheet.Range("A11:B11"));

        var serviceRow = 12;

        foreach (
            var service
            in statistics.ReservationsByService)
        {
            worksheet.Cell(serviceRow, 1)
                .Value = service.ServiceName;

            worksheet.Cell(serviceRow, 2)
                .Value = service.Count;

            serviceRow++;
        }

        // ==========================================
        // STATUSI
        // ==========================================

        var statusStartRow =
            serviceRow + 2;

        worksheet.Cell(statusStartRow, 1)
            .Value = "Status termina";

        worksheet.Cell(statusStartRow, 1)
            .Style.Font.Bold = true;

        worksheet.Cell(statusStartRow + 1, 1)
            .Value = "Status";

        worksheet.Cell(statusStartRow + 1, 2)
            .Value = "Broj termina";

        StyleExcelHeader(
            worksheet.Range(
                statusStartRow + 1,
                1,
                statusStartRow + 1,
                2));

        var statusRow =
            statusStartRow + 2;

        foreach (
            var item
            in statistics.ReservationsByStatus)
        {
            worksheet.Cell(statusRow, 1)
                .Value =
                GetPdfStatusName(item.Status);

            worksheet.Cell(statusRow, 2)
                .Value = item.Count;

            statusRow++;
        }

        // ==========================================
        // TERMINI PO DANIMA
        // ==========================================

        var dailyStartRow =
            statusRow + 2;

        worksheet.Cell(dailyStartRow, 1)
            .Value = "Broj termina po danima";

        worksheet.Cell(dailyStartRow, 1)
            .Style.Font.Bold = true;

        worksheet.Cell(dailyStartRow + 1, 1)
            .Value = "Datum";

        worksheet.Cell(dailyStartRow + 1, 2)
            .Value = "Broj termina";

        StyleExcelHeader(
            worksheet.Range(
                dailyStartRow + 1,
                1,
                dailyStartRow + 1,
                2));

        var dailyRow =
            dailyStartRow + 2;

        foreach (
            var item
            in statistics.ReservationsByDay)
        {
            worksheet.Cell(dailyRow, 1)
                .Value = item.Date;

            worksheet.Cell(dailyRow, 1)
                .Style.DateFormat.Format =
                "dd.MM.yyyy.";

            worksheet.Cell(dailyRow, 2)
                .Value = item.Count;

            dailyRow++;
        }

        // ==========================================
        // FORMATIRANJE
        // ==========================================

        worksheet.Column(1)
            .Width = 30;

        worksheet.Column(2)
            .Width = 18;

        worksheet.SheetView.FreezeRows(11);

        worksheet.RangeUsed()
            .Style.Alignment.Vertical =
            XLAlignmentVerticalValues.Center;

        workbook.SaveAs(filePath);
    }

    private void StyleExcelHeader(
    IXLRange range)
    {
        range.Style.Font.Bold = true;

        range.Style.Font.FontColor =
            XLColor.White;

        range.Style.Fill.BackgroundColor =
            XLColor.FromHtml("#6D4C73");

        range.Style.Alignment.Horizontal =
            XLAlignmentHorizontalValues.Center;

        range.Style.Alignment.Vertical =
            XLAlignmentVerticalValues.Center;
    }

    private void DrawPieChart(
    Canvas canvas,
    StackPanel legend,
    List<PieChartItem> items)
    {
        canvas.Children.Clear();
        legend.Children.Clear();

        if (items.Count == 0)
            return;

        var total =
            items.Sum(x => x.Value);

        if (total == 0)
            return;

        var colors = new[]
        {
        Color.FromRgb(109, 76, 115),
        Color.FromRgb(156, 39, 176),
        Color.FromRgb(186, 104, 200),
        Color.FromRgb(121, 85, 72),
        Color.FromRgb(126, 87, 194),
        Color.FromRgb(84, 110, 122)
    };

        var centerX = canvas.Width / 2;
        var centerY = canvas.Height / 2;
        var radius = 70.0;

        double startAngle = -90;

        for (var i = 0; i < items.Count; i++)
        {
            var item = items[i];

            var percentage =
                (double)item.Value / total;

            var sweepAngle =
                percentage * 360;

            var path = CreatePieSlice(
                centerX,
                centerY,
                radius,
                startAngle,
                sweepAngle);

            path.Fill =
                new SolidColorBrush(
                    colors[i % colors.Length]);

            path.Stroke = Brushes.White;
            path.StrokeThickness = 2;

            canvas.Children.Add(path);

            var legendItem = new StackPanel
            {
                Orientation = Orientation.Horizontal,
                Margin = new Thickness(0, 3, 0, 3)
            };

            var colorBox = new Border
            {
                Width = 10,
                Height = 10,
                Background =
                    new SolidColorBrush(
                        colors[i % colors.Length]),
                CornerRadius = new CornerRadius(2),
                Margin = new Thickness(0, 0, 6, 0)
            };

            var text = new TextBlock
            {
                Text =
                    $"{item.Name} ({item.Value})",
                FontSize = 11,
                Foreground =
                    new SolidColorBrush(
                        Color.FromRgb(80, 70, 85))
            };

            legendItem.Children.Add(colorBox);
            legendItem.Children.Add(text);

            legend.Children.Add(legendItem);

            startAngle += sweepAngle;
        }
    }

    private Path CreatePieSlice(
    double centerX,
    double centerY,
    double radius,
    double startAngle,
    double sweepAngle)
    {
        var startRadians =
            startAngle * Math.PI / 180;

        var endRadians =
            (startAngle + sweepAngle) *
            Math.PI / 180;

        var startPoint =
            new Point(
                centerX +
                radius * Math.Cos(startRadians),
                centerY +
                radius * Math.Sin(startRadians));

        var endPoint =
            new Point(
                centerX +
                radius * Math.Cos(endRadians),
                centerY +
                radius * Math.Sin(endRadians));

        var isLargeArc =
            sweepAngle > 180;

        var geometry = new StreamGeometry();

        using (var context = geometry.Open())
        {
            context.BeginFigure(
                new Point(centerX, centerY),
                true,
                true);

            context.LineTo(
                startPoint,
                true,
                true);

            context.ArcTo(
                endPoint,
                new Size(radius, radius),
                0,
                isLargeArc,
                SweepDirection.Clockwise,
                true,
                true);
        }

        return new Path
        {
            Data = geometry
        };
    }
}

public class DashboardStatisticsDto
{
    public int TotalAppointments { get; set; }

    public decimal TotalRevenue { get; set; }

    public string? MostPopularService { get; set; }

    public int MostPopularServiceCount { get; set; }

    public List<DailyReservationDto> ReservationsByDay { get; set; } = [];

    public List<ReservationStatusDto> ReservationsByStatus { get; set; } = [];
    public List<ServiceReservationDto> ReservationsByService { get; set; } = [];
}


public class DailyReservationDto
{
    public DateTime Date { get; set; }

    public int Count { get; set; }
    public List<ServiceReservationDto> ReservationsByService { get; set; } = [];
}

public class ServiceReservationDto
{
    public string ServiceName { get; set; } = "";

    public int Count { get; set; }
}

public class ReservationStatusDto
{
    public string Status { get; set; } = "";

    public int Count { get; set; }
}

public class PieChartItem
{
    public string Name { get; set; } = "";

    public int Value { get; set; }
}