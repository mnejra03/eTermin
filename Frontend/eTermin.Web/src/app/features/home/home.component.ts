import { Component, OnInit } from '@angular/core';
import { RouterLink } from '@angular/router';
import { CommonModule } from '@angular/common';

import { NavbarComponent } from '../../shared/components/navbar/navbar.component';
import { SalonService } from '../../core/services/salon.service';
import { Salon } from '../../shared/models/salon.model';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [
    CommonModule,
    RouterLink,
    NavbarComponent
  ],
  templateUrl: './home.component.html',
  styleUrl: './home.component.scss'
})
export class HomeComponent implements OnInit {

  salons: Salon[] = [];
  isLoading = true;
  errorMessage = '';

  constructor(
    private salonService: SalonService
  ) {}

  ngOnInit(): void {
    this.loadSalons();
  }

  private loadSalons(): void {
    this.salonService.getAll().subscribe({
      next: salons => {
        this.salons = salons.filter(salon => salon.isActive);
        this.isLoading = false;
      },
      error: () => {
        this.errorMessage =
          'Saloni trenutno nisu dostupni.';
        this.isLoading = false;
      }
    });
  }
}