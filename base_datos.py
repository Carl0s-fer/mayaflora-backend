import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import datetime
import hashlib
import os

class BaseDatos:
    def __init__(self, connection_string=None):
        """
        Inicializa la conexión a PostgreSQL
        connection_string: URL de conexión de Supabase
        """
        self.connection_string = connection_string or os.getenv("DATABASE_URL")
        if not self.connection_string:
            raise ValueError("❌ No se encontró DATABASE_URL en las variables de entorno")
        self.inicializar_base_datos()
    
    def obtener_conexion(self):
        """Crea y retorna una conexión a PostgreSQL"""
        conexion = psycopg2.connect(self.connection_string)
        return conexion
    
    def inicializar_base_datos(self):
        """Crea las tablas si no existen"""
        conexion = self.obtener_conexion()
        cursor = conexion.cursor()
        
        # Tabla de usuarios
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS usuarios (
                id SERIAL PRIMARY KEY,
                nombre_usuario VARCHAR(100) UNIQUE NOT NULL,
                contrasena VARCHAR(255) NOT NULL,
                fecha_creacion TIMESTAMP NOT NULL
            )
        ''')
        
        # Tabla de historial de escaneos
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS historial_escaneos (
                id SERIAL PRIMARY KEY,
                usuario_id INTEGER NOT NULL,
                nombre_usuario VARCHAR(100) NOT NULL,
                ruta_imagen TEXT,
                resultado VARCHAR(50) NOT NULL,
                confianza REAL NOT NULL,
                fecha_escaneo TIMESTAMP NOT NULL,
                FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE
            )
        ''')
        
        # Crear índices para mejorar rendimiento
        cursor.execute('''
            CREATE INDEX IF NOT EXISTS idx_historial_usuario 
            ON historial_escaneos(usuario_id)
        ''')
        
        cursor.execute('''
            CREATE INDEX IF NOT EXISTS idx_historial_fecha 
            ON historial_escaneos(fecha_escaneo DESC)
        ''')
        
        conexion.commit()
        cursor.close()
        conexion.close()
        print("✅ Base de datos PostgreSQL inicializada correctamente")
    
    def encriptar_contrasena(self, contrasena):
        """Encripta la contraseña usando SHA256"""
        return hashlib.sha256(contrasena.encode()).hexdigest()
    
    def crear_usuario(self, nombre_usuario, contrasena):
        """Crea un nuevo usuario"""
        try:
            conexion = self.obtener_conexion()
            cursor = conexion.cursor()
            
            contrasena_encriptada = self.encriptar_contrasena(contrasena)
            fecha_actual = datetime.now()
            
            cursor.execute('''
                INSERT INTO usuarios (nombre_usuario, contrasena, fecha_creacion)
                VALUES (%s, %s, %s)
                RETURNING id
            ''', (nombre_usuario, contrasena_encriptada, fecha_actual))
            
            usuario_id = cursor.fetchone()[0]
            conexion.commit()
            cursor.close()
            conexion.close()
            
            return {"exito": True, "mensaje": "Usuario creado exitosamente", "usuario_id": usuario_id}
        except psycopg2.IntegrityError:
            return {"exito": False, "mensaje": "El usuario ya existe"}
        except Exception as e:
            return {"exito": False, "mensaje": f"Error al crear usuario: {str(e)}"}
    
    def verificar_usuario(self, nombre_usuario, contrasena):
        """Verifica las credenciales del usuario"""
        try:
            conexion = self.obtener_conexion()
            cursor = conexion.cursor(cursor_factory=RealDictCursor)
            
            contrasena_encriptada = self.encriptar_contrasena(contrasena)
            
            cursor.execute('''
                SELECT id, nombre_usuario FROM usuarios
                WHERE nombre_usuario = %s AND contrasena = %s
            ''', (nombre_usuario, contrasena_encriptada))
            
            usuario = cursor.fetchone()
            cursor.close()
            conexion.close()
            
            if usuario:
                return {
                    "exito": True,
                    "mensaje": "Inicio de sesión exitoso",
                    "usuario": {
                        "id": usuario["id"],
                        "nombre_usuario": usuario["nombre_usuario"]
                    }
                }
            else:
                return {"exito": False, "mensaje": "Usuario o contraseña incorrectos"}
        except Exception as e:
            return {"exito": False, "mensaje": f"Error al verificar usuario: {str(e)}"}
    
    def guardar_escaneo(self, usuario_id, nombre_usuario, ruta_imagen, resultado, confianza):
        """Guarda un registro de escaneo en el historial"""
        try:
            conexion = self.obtener_conexion()
            cursor = conexion.cursor()
            
            fecha_actual = datetime.now()
            
            cursor.execute('''
                INSERT INTO historial_escaneos 
                (usuario_id, nombre_usuario, ruta_imagen, resultado, confianza, fecha_escaneo)
                VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING id
            ''', (usuario_id, nombre_usuario, ruta_imagen, resultado, confianza, fecha_actual))
            
            escaneo_id = cursor.fetchone()[0]
            conexion.commit()
            cursor.close()
            conexion.close()
            
            return {"exito": True, "mensaje": "Escaneo guardado exitosamente", "escaneo_id": escaneo_id}
        except Exception as e:
            return {"exito": False, "mensaje": f"Error al guardar escaneo: {str(e)}"}
    
    def obtener_historial(self, usuario_id):
        """Obtiene el historial de escaneos de un usuario"""
        try:
            conexion = self.obtener_conexion()
            cursor = conexion.cursor(cursor_factory=RealDictCursor)
            
            cursor.execute('''
                SELECT * FROM historial_escaneos
                WHERE usuario_id = %s
                ORDER BY fecha_escaneo DESC
            ''', (usuario_id,))
            
            escaneos = cursor.fetchall()
            cursor.close()
            conexion.close()
            
            historial = []
            for escaneo in escaneos:
                historial.append({
                    "id": escaneo["id"],
                    "nombre_usuario": escaneo["nombre_usuario"],
                    "resultado": escaneo["resultado"],
                    "confianza": escaneo["confianza"],
                    "fecha_escaneo": escaneo["fecha_escaneo"].isoformat()
                })
            
            return {"exito": True, "historial": historial}
        except Exception as e:
            return {"exito": False, "mensaje": f"Error al obtener historial: {str(e)}"}

# Para pruebas
if __name__ == "__main__":
    # Prueba solo si tienes DATABASE_URL en .env
    try:
        db = BaseDatos()
        print("✅ Conexión exitosa a PostgreSQL")
    except Exception as e:
        print(f"❌ Error: {e}")