import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { ApiService } from './api.service';
import { Salon } from '../../shared/models/salon.model';

@Injectable({
  providedIn: 'root'
})
export class SalonService {

  constructor(private api: ApiService) {}

  getAll(): Observable<Salon[]> {
    return this.api.get<Salon[]>('Salons');
  }

  getById(id: number): Observable<Salon> {
    return this.api.get<Salon>(`Salons/${id}`);
  }
}