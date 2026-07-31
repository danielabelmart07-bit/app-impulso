from django.contrib import admin
from .models import Tarea, PerfilUsuario

# Registramos nuestros modelos para que aparezcan en el panel de control
admin.site.register(Tarea)
admin.site.register(PerfilUsuario)
