from django.core.management.base import BaseCommand
from django.utils import timezone
from tareas.models import Tarea

class Command(BaseCommand):
    help = 'Elimina las tareas pendientes que fueron creadas en días anteriores a hoy.'

    def handle(self, *args, **kwargs):
        hoy = timezone.now().date()
        
        # Filtramos las tareas creadas ANTES de hoy que no fueron completadas
        tareas_viejas = Tarea.objects.filter(fecha_creacion__date__lt=hoy)
        
        cantidad_eliminadas, _ = tareas_viejas.delete()
        
        self.stdout.write(
            self.style.SUCCESS(f'Limpieza completada: se eliminaron {cantidad_eliminadas} tareas antiguas.')
        )