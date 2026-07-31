from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.utils import timezone
from django.shortcuts import get_object_or_404
from .models import Tarea
from .serializers import TareaSerializer

# 1. REGISTRO DE USUARIO
@api_view(['POST'])
@permission_classes([AllowAny])
def registro_usuario(request):
    username = request.data.get('username')
    password = request.data.get('password')

    if not username or not password:
        return Response({'error': 'Faltan datos requeridos'}, status=status.HTTP_400_BAD_REQUEST)

    if User.objects.filter(username=username).exists():
        return Response({'error': 'El nombre de usuario ya existe'}, status=status.HTTP_400_BAD_REQUEST)

    usuario = User.objects.create_user(username=username, password=password)
    token, _ = Token.objects.get_or_create(user=usuario)

    return Response({'token': token.key, 'username': usuario.username}, status=status.HTTP_201_CREATED)


# 2. INICIO DE SESIÓN
@api_view(['POST'])
@permission_classes([AllowAny])
def login_usuario(request):
    username = request.data.get('username')
    password = request.data.get('password')

    usuario = authenticate(username=username, password=password)
    if not usuario:
        return Response({'error': 'Credenciales inválidas'}, status=status.HTTP_400_BAD_REQUEST)

    token, _ = Token.objects.get_or_create(user=usuario)
    return Response({'token': token.key, 'username': usuario.username}, status=status.HTTP_200_OK)


# 3. LISTAR Y CREAR TAREAS
@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def lista_tareas_hoy(request):
    if request.method == 'GET':
        hoy = timezone.now().date()
        tareas = Tarea.objects.filter(
            usuario=request.user,
            completada=False,
            fecha_creacion__date=hoy
        )
        serializer = TareaSerializer(tareas, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    elif request.method == 'POST':
        serializer = TareaSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(usuario=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# 4. MARCAR TAREA COMO COMPLETADA
@api_view(['POST', 'PATCH'])
@permission_classes([IsAuthenticated])
def completar_tarea(request, tarea_id):
    tarea = get_object_or_404(Tarea, id=tarea_id, usuario=request.user)
    tarea.completada = True
    tarea.save()
    return Response({'mensaje': 'Tarea completada exitosamente'}, status=status.HTTP_200_OK)


# 5. EDITAR TAREA
@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def editar_tarea(request, tarea_id):
    tarea = get_object_or_404(Tarea, id=tarea_id, usuario=request.user)
    serializer = TareaSerializer(tarea, data=request.data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_200_OK)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# 6. ELIMINAR TAREA
@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def eliminar_tarea(request, tarea_id):
    tarea = get_object_or_404(Tarea, id=tarea_id, usuario=request.user)
    tarea.delete()
    return Response({'mensaje': 'Tarea eliminada exitosamente'}, status=status.HTTP_204_NO_CONTENT)