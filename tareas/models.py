from django.db import models
from django.contrib.auth.models import User

class PerfilUsuario(models.Model):
    # Relación de 1 a 1 con el usuario de Django
    usuario = models.OneToOneField(User, on_delete=models.CASCADE)
    
    # Contador acumulativo que nunca se reinicia
    tareas_completadas_totales = models.IntegerField(default=0)

    def __str__(self):
        return f"Perfil de {self.usuario.username}"


class Tarea(models.Model):
    usuario = models.ForeignKey(User, on_delete=models.CASCADE)
    titulo = models.CharField(max_length=200)
    descripcion = models.TextField(blank=True, null=True)
    completada = models.BooleanField(default=False)
    fecha_creacion = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.titulo