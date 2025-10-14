import sqlite3
from datetime import datetime
import hashlib

class BaseDatos:
    def __init__(self, nombre_db="mayaflora.db"):
        self.nombre_db = nombre_db
        self.inicializar_base_datos()
    
    def obtener_conexion(self):
        """Crea y retorna una conexión a la base de datos"""
        conexion = sqlite3.connect(self.nombre_db)
        conexion.row_factory = sqlite3.Row
        return conexion
    
    def inicializar_base_datos(self):
        """Crea las tablas si no existen"""
        conexion = self.obtener_conexion()
        cursor = conexion.cursor()
        
        # Tabla de usuarios
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS usuarios (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nombre_usuario TEXT UNIQUE NOT NULL,
                contrasena TEXT NOT NULL,
                fecha_creacion TEXT NOT NULL
            )
        ''')
        
        # Tabla de historial de escaneos
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS historial_escaneos (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                usuario_id INTEGER NOT NULL,
                nombre_usuario TEXT NOT NULL,
                ruta_imagen TEXT,
                resultado TEXT NOT NULL,
                confianza REAL NOT NULL,
                fecha_escaneo TEXT NOT NULL,
                FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
            )
        ''')
        
        conexion.commit()
        conexion.close()
        print("✅ Base de datos inicializada correctamente")
    
    def encriptar_contrasena(self, contrasena):
        """Encripta la contraseña usando SHA256"""
        return hashlib.sha256(contrasena.encode()).hexdigest()
    
    def crear_usuario(self, nombre_usuario, contrasena):
        """Crea un nuevo usuario"""
        try:
            conexion = self.obtener_conexion()
            cursor = conexion.cursor()
            
            contrasena_encriptada = self.encriptar_contrasena(contrasena)
            fecha_actual = datetime.now().isoformat()
            
            cursor.execute('''
                INSERT INTO usuarios (nombre_usuario, contrasena, fecha_creacion)
                VALUES (?, ?, ?)
            ''', (nombre_usuario, contrasena_encriptada, fecha_actual))
            
            conexion.commit()
            usuario_id = cursor.lastrowid
            conexion.close()
            
            return {"exito": True, "mensaje": "Usuario creado exitosamente", "usuario_id": usuario_id}
        except sqlite3.IntegrityError:
            return {"exito": False, "mensaje": "El usuario ya existe"}
        except Exception as e:
            return {"exito": False, "mensaje": f"Error al crear usuario: {str(e)}"}
    
    def verificar_usuario(self, nombre_usuario, contrasena):
        """Verifica las credenciales del usuario"""
        try:
            conexion = self.obtener_conexion()
            cursor = conexion.cursor()
            
            contrasena_encriptada = self.encriptar_contrasena(contrasena)
            
            cursor.execute('''
                SELECT id, nombre_usuario FROM usuarios
                WHERE nombre_usuario = ? AND contrasena = ?
            ''', (nombre_usuario, contrasena_encriptada))
            
            usuario = cursor.fetchone()
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
            
            fecha_actual = datetime.now().isoformat()
            
            cursor.execute('''
                INSERT INTO historial_escaneos 
                (usuario_id, nombre_usuario, ruta_imagen, resultado, confianza, fecha_escaneo)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (usuario_id, nombre_usuario, ruta_imagen, resultado, confianza, fecha_actual))
            
            conexion.commit()
            escaneo_id = cursor.lastrowid
            conexion.close()
            
            return {"exito": True, "mensaje": "Escaneo guardado exitosamente", "escaneo_id": escaneo_id}
        except Exception as e:
            return {"exito": False, "mensaje": f"Error al guardar escaneo: {str(e)}"}
    
    def obtener_historial(self, usuario_id):
        """Obtiene el historial de escaneos de un usuario"""
        try:
            conexion = self.obtener_conexion()
            cursor = conexion.cursor()
            
            cursor.execute('''
                SELECT * FROM historial_escaneos
                WHERE usuario_id = ?
                ORDER BY fecha_escaneo DESC
            ''', (usuario_id,))
            
            escaneos = cursor.fetchall()
            conexion.close()
            
            historial = []
            for escaneo in escaneos:
                historial.append({
                    "id": escaneo["id"],
                    "nombre_usuario": escaneo["nombre_usuario"],
                    "resultado": escaneo["resultado"],
                    "confianza": escaneo["confianza"],
                    "fecha_escaneo": escaneo["fecha_escaneo"]
                })
            
            return {"exito": True, "historial": historial}
        except Exception as e:
            return {"exito": False, "mensaje": f"Error al obtener historial: {str(e)}"}

# Para pruebas
if __name__ == "__main__":
    db = BaseDatos()
    
    # Crear usuario de prueba
    resultado = db.crear_usuario("admin", "admin123")
    print(resultado)
    
    # Verificar usuario
    resultado = db.verificar_usuario("admin", "admin123")
    print(resultado)