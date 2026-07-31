from django.urls import path
from . import views

urlpatterns = [
    # Autenticación
    path('registro/', views.registro_usuario, name='registro'),
    path('login/', views.login_usuario, name='login'),
    
    # Tareas
    path('tareas/', views.lista_tareas_hoy, name='lista_tareas_hoy'),
    path('tareas/<int:tarea_id>/completar/', views.completar_tarea, name='completar_tarea'),
    path('tareas/<int:tarea_id>/editar/', views.editar_tarea, name='editar_tarea'),
    path('tareas/<int:tarea_id>/eliminar/', views.eliminar_tarea, name='eliminar_tarea'),
]