from rest_framework import serializers
from .models import Tarea

class TareaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Tarea
        # Agregamos 'titulo' a la lista de campos expuestos por la API
        fields = ['id', 'titulo', 'descripcion', 'completada', 'fecha_creacion', 'usuario']
        
        # 'usuario' es de solo lectura porque se asigna automáticamente desde request.user en la vista
        read_only_fields = ['id', 'fecha_creacion', 'usuario']