import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import datetime
import hashlib
import os
import base64
import io
from PIL import Image as PILImage

class BaseDatos:
    def __init__(self, connection_string=None):
        self.connection_string = connection_string or os.getenv("DATABASE_URL")
        if not self.connection_string:
            raise ValueError("❌ No se encontró DATABASE_URL en las variables de entorno")
        self.inicializar_base_datos()

    def obtener_conexion(self):
        import socket
        old_getaddrinfo = socket.getaddrinfo
        def new_getaddrinfo(*args, **kwargs):
            responses = old_getaddrinfo(*args, **kwargs)
            return [response for response in responses if response[0] == socket.AF_INET]
        socket.getaddrinfo = new_getaddrinfo
        conexion = psycopg2.connect(self.connection_string)
        socket.getaddrinfo = old_getaddrinfo
        return conexion

    def inicializar_base_datos(self):
        conexion = self.obtener_conexion()
        cursor = conexion.cursor()

        cursor.execute('''
            CREATE TABLE IF NOT EXISTS usuarios (
                id SERIAL PRIMARY KEY,
                nombre_usuario VARCHAR(100) UNIQUE NOT NULL,
                contrasena VARCHAR(255) NOT NULL,
                fecha_creacion TIMESTAMP NOT NULL
            )
        ''')

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

        cursor.execute('''
            CREATE TABLE IF NOT EXISTS carpetas (
                id SERIAL PRIMARY KEY,
                usuario_id INTEGER NOT NULL,
                nombre VARCHAR(150) NOT NULL,
                fecha_creacion TIMESTAMP NOT NULL,
                FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE
            )
        ''')

        cursor.execute('''
            CREATE TABLE IF NOT EXISTS plantas (
                id SERIAL PRIMARY KEY,
                carpeta_id INTEGER NOT NULL,
                usuario_id INTEGER NOT NULL,
                nombre VARCHAR(150) NOT NULL,
                foto_perfil_base64 TEXT,
                estado_actual VARCHAR(20) DEFAULT 'Sin diagnostico',
                paso_tratamiento_actual INTEGER DEFAULT 0,
                notificaciones_activas BOOLEAN DEFAULT FALSE,
                fecha_creacion TIMESTAMP NOT NULL,
                fecha_ultimo_escaneo TIMESTAMP,
                FOREIGN KEY (carpeta_id) REFERENCES carpetas (id) ON DELETE CASCADE,
                FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE
            )
        ''')

        cursor.execute('''
            CREATE TABLE IF NOT EXISTS escaneos_planta (
                id SERIAL PRIMARY KEY,
                planta_id INTEGER NOT NULL,
                imagen_base64 TEXT,
                resultado VARCHAR(20) NOT NULL,
                confianza REAL NOT NULL,
                instrucciones TEXT,
                paso_numero INTEGER DEFAULT 0,
                es_foto_seguimiento BOOLEAN DEFAULT FALSE,
                tratamiento_completado BOOLEAN DEFAULT FALSE,
                fecha_escaneo TIMESTAMP NOT NULL,
                FOREIGN KEY (planta_id) REFERENCES plantas (id) ON DELETE CASCADE
            )
        ''')

        cursor.execute('CREATE INDEX IF NOT EXISTS idx_historial_usuario ON historial_escaneos(usuario_id)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_historial_fecha ON historial_escaneos(fecha_escaneo DESC)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_carpetas_usuario ON carpetas(usuario_id)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_plantas_carpeta ON plantas(carpeta_id)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_escaneos_planta ON escaneos_planta(planta_id)')

        conexion.commit()
        cursor.close()
        conexion.close()
        print("✅ Base de datos PostgreSQL inicializada correctamente")

    def encriptar_contrasena(self, contrasena):
        return hashlib.sha256(contrasena.encode()).hexdigest()

    def comprimir_imagen_base64(self, imagen_bytes, max_size=800, quality=70):
        """Comprime la imagen y la devuelve como base64"""
        try:
            img = PILImage.open(io.BytesIO(imagen_bytes)).convert('RGB')
            img.thumbnail((max_size, max_size), PILImage.LANCZOS)
            buf = io.BytesIO()
            img.save(buf, format='JPEG', quality=quality)
            return base64.b64encode(buf.getvalue()).decode('utf-8')
        except Exception:
            return base64.b64encode(imagen_bytes).decode('utf-8')

    # ─── Usuarios ────────────────────────────────────────────────────────────

    def crear_usuario(self, nombre_usuario, contrasena):
        try:
            conexion = self.obtener_conexion()
            cursor = conexion.cursor()
            contrasena_enc = self.encriptar_contrasena(contrasena)
            cursor.execute(
                'INSERT INTO usuarios (nombre_usuario, contrasena, fecha_creacion) VALUES (%s, %s, %s) RETURNING id',
                (nombre_usuario, contrasena_enc, datetime.now())
            )
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
        try:
            conexion = self.obtener_conexion()
            cursor = conexion.cursor(cursor_factory=RealDictCursor)
            contrasena_enc = self.encriptar_contrasena(contrasena)
            cursor.execute(
                'SELECT id, nombre_usuario FROM usuarios WHERE nombre_usuario = %s AND contrasena = %s',
                (nombre_usuario, contrasena_enc)
            )
            usuario = cursor.fetchone()
            cursor.close()
            conexion.close()
            if usuario:
                return {"exito": True, "mensaje": "Inicio de sesión exitoso",
                        "usuario": {"id": usuario["id"], "nombre_usuario": usuario["nombre_usuario"]}}
            return {"exito": False, "mensaje": "Usuario o contraseña incorrectos"}
        except Exception as e:
            return {"exito": False, "mensaje": f"Error al verificar usuario: {str(e)}"}

    # ─── Historial general ────────────────────────────────────────────────────

    def guardar_escaneo(self, usuario_id, nombre_usuario, ruta_imagen, resultado, confianza):
        try:
            conexion = self.obtener_conexion()
            cursor = conexion.cursor()
            cursor.execute(
                'INSERT INTO historial_escaneos (usuario_id, nombre_usuario, ruta_imagen, resultado, confianza, fecha_escaneo) VALUES (%s, %s, %s, %s, %s, %s) RETURNING id',
                (usuario_id, nombre_usuario, ruta_imagen, resultado, confianza, datetime.now())
            )
            escaneo_id = cursor.fetchone()[0]
            conexion.commit()
            cursor.close()
            conexion.close()
            return {"exito": True, "mensaje": "Escaneo guardado exitosamente", "escaneo_id": escaneo_id}
        except Exception as e:
            return {"exito": False, "mensaje": f"Error al guardar escaneo: {str(e)}"}

    def obtener_historial(self, usuario_id):
        try:
            conexion = self.obtener_conexion()
            cursor = conexion.cursor(cursor_factory=RealDictCursor)
            cursor.execute(
                'SELECT * FROM historial_escaneos WHERE usuario_id = %s ORDER BY fecha_escaneo DESC',
                (usuario_id,)
            )
            escaneos = cursor.fetchall()
            cursor.close()
            conexion.close()
            historial = [{"id": e["id"], "nombre_usuario": e["nombre_usuario"], "resultado": e["resultado"],
                          "confianza": e["confianza"], "fecha_escaneo": e["fecha_escaneo"].isoformat()} for e in escaneos]
            return {"exito": True, "historial": historial}
        except Exception as e:
            return {"exito": False, "mensaje": f"Error al obtener historial: {str(e)}"}

    # ─── Carpetas ─────────────────────────────────────────────────────────────

    def crear_carpeta(self, usuario_id, nombre):
        try:
            conexion = self.obtener_conexion()
            cursor = conexion.cursor()
            cursor.execute(
                'INSERT INTO carpetas (usuario_id, nombre, fecha_creacion) VALUES (%s, %s, %s) RETURNING id',
                (usuario_id, nombre, datetime.now())
            )
            carpeta_id = cursor.fetchone()[0]
            conexion.commit()
            cursor.close()
            conexion.close()
            return {"exito": True, "carpeta_id": carpeta_id}
        except Exception as e:
            return {"exito": False, "mensaje": str(e)}

    def obtener_carpetas(self, usuario_id):
        try:
            conexion = self.obtener_conexion()
            cursor = conexion.cursor(cursor_factory=RealDictCursor)
            cursor.execute('''
                SELECT c.*,
                    COUNT(p.id) as total_plantas,
                    SUM(CASE WHEN p.estado_actual = 'Enferma' THEN 1 ELSE 0 END) as plantas_enfermas,
                    SUM(CASE WHEN p.estado_actual = 'Sana' THEN 1 ELSE 0 END) as plantas_sanas
                FROM carpetas c
                LEFT JOIN plantas p ON p.carpeta_id = c.id
                WHERE c.usuario_id = %s
                GROUP BY c.id
                ORDER BY c.fecha_creacion DESC
            ''', (usuario_id,))
            carpetas = cursor.fetchall()
            cursor.close()
            conexion.close()
            return {"exito": True, "carpetas": [
                {"id": c["id"], "nombre": c["nombre"],
                 "fecha_creacion": c["fecha_creacion"].isoformat(),
                 "total_plantas": c["total_plantas"],
                 "plantas_enfermas": int(c["plantas_enfermas"] or 0),
                 "plantas_sanas": int(c["plantas_sanas"] or 0)} for c in carpetas
            ]}
        except Exception as e:
            return {"exito": False, "mensaje": str(e)}

    def actualizar_carpeta(self, carpeta_id, nombre):
        try:
            conexion = self.obtener_conexion()
            cursor = conexion.cursor()
            cursor.execute('UPDATE carpetas SET nombre = %s WHERE id = %s', (nombre, carpeta_id))
            conexion.commit()
            cursor.close()
            conexion.close()
            return {"exito": True}
        except Exception as e:
            return {"exito": False, "mensaje": str(e)}

    def eliminar_carpeta(self, carpeta_id):
        try:
            conexion = self.obtener_conexion()
            cursor = conexion.cursor()
            cursor.execute('DELETE FROM carpetas WHERE id = %s', (carpeta_id,))
            conexion.commit()
            cursor.close()
            conexion.close()
            return {"exito": True}
        except Exception as e:
            return {"exito": False, "mensaje": str(e)}

    # ─── Plantas ─────────────────────────────────────────────────────────────

    def crear_planta(self, carpeta_id, usuario_id, nombre, foto_perfil_bytes=None):
        try:
            foto_b64 = None
            if foto_perfil_bytes:
                foto_b64 = self.comprimir_imagen_base64(foto_perfil_bytes, max_size=600, quality=75)
            conexion = self.obtener_conexion()
            cursor = conexion.cursor()
            cursor.execute(
                'INSERT INTO plantas (carpeta_id, usuario_id, nombre, foto_perfil_base64, fecha_creacion) VALUES (%s, %s, %s, %s, %s) RETURNING id',
                (carpeta_id, usuario_id, nombre, foto_b64, datetime.now())
            )
            planta_id = cursor.fetchone()[0]
            conexion.commit()
            cursor.close()
            conexion.close()
            return {"exito": True, "planta_id": planta_id}
        except Exception as e:
            return {"exito": False, "mensaje": str(e)}

    def obtener_plantas(self, carpeta_id):
        try:
            conexion = self.obtener_conexion()
            cursor = conexion.cursor(cursor_factory=RealDictCursor)
            cursor.execute(
                'SELECT * FROM plantas WHERE carpeta_id = %s ORDER BY fecha_creacion DESC',
                (carpeta_id,)
            )
            plantas = cursor.fetchall()
            cursor.close()
            conexion.close()
            return {"exito": True, "plantas": [
                {"id": p["id"], "nombre": p["nombre"],
                 "foto_perfil_base64": p["foto_perfil_base64"],
                 "estado_actual": p["estado_actual"],
                 "paso_tratamiento_actual": p["paso_tratamiento_actual"],
                 "notificaciones_activas": p["notificaciones_activas"],
                 "fecha_creacion": p["fecha_creacion"].isoformat(),
                 "fecha_ultimo_escaneo": p["fecha_ultimo_escaneo"].isoformat() if p["fecha_ultimo_escaneo"] else None}
                for p in plantas
            ]}
        except Exception as e:
            return {"exito": False, "mensaje": str(e)}

    def obtener_planta(self, planta_id):
        try:
            conexion = self.obtener_conexion()
            cursor = conexion.cursor(cursor_factory=RealDictCursor)
            cursor.execute('SELECT * FROM plantas WHERE id = %s', (planta_id,))
            p = cursor.fetchone()
            cursor.close()
            conexion.close()
            if not p:
                return {"exito": False, "mensaje": "Planta no encontrada"}
            return {"exito": True, "planta": {
                "id": p["id"], "nombre": p["nombre"],
                "foto_perfil_base64": p["foto_perfil_base64"],
                "estado_actual": p["estado_actual"],
                "paso_tratamiento_actual": p["paso_tratamiento_actual"],
                "notificaciones_activas": p["notificaciones_activas"],
                "fecha_creacion": p["fecha_creacion"].isoformat(),
                "fecha_ultimo_escaneo": p["fecha_ultimo_escaneo"].isoformat() if p["fecha_ultimo_escaneo"] else None
            }}
        except Exception as e:
            return {"exito": False, "mensaje": str(e)}

    def actualizar_planta(self, planta_id, nombre=None, foto_perfil_bytes=None,
                          estado_actual=None, paso_tratamiento_actual=None,
                          notificaciones_activas=None):
        try:
            conexion = self.obtener_conexion()
            cursor = conexion.cursor()
            campos = []
            valores = []
            if nombre is not None:
                campos.append("nombre = %s")
                valores.append(nombre)
            if foto_perfil_bytes is not None:
                foto_b64 = self.comprimir_imagen_base64(foto_perfil_bytes, max_size=600, quality=75)
                campos.append("foto_perfil_base64 = %s")
                valores.append(foto_b64)
            if estado_actual is not None:
                campos.append("estado_actual = %s")
                valores.append(estado_actual)
            if paso_tratamiento_actual is not None:
                campos.append("paso_tratamiento_actual = %s")
                valores.append(paso_tratamiento_actual)
            if notificaciones_activas is not None:
                campos.append("notificaciones_activas = %s")
                valores.append(notificaciones_activas)
            if not campos:
                return {"exito": False, "mensaje": "Nada que actualizar"}
            valores.append(planta_id)
            cursor.execute(f'UPDATE plantas SET {", ".join(campos)} WHERE id = %s', valores)
            conexion.commit()
            cursor.close()
            conexion.close()
            return {"exito": True}
        except Exception as e:
            return {"exito": False, "mensaje": str(e)}

    def eliminar_planta(self, planta_id):
        try:
            conexion = self.obtener_conexion()
            cursor = conexion.cursor()
            cursor.execute('DELETE FROM plantas WHERE id = %s', (planta_id,))
            conexion.commit()
            cursor.close()
            conexion.close()
            return {"exito": True}
        except Exception as e:
            return {"exito": False, "mensaje": str(e)}

    # ─── Escaneos de plantas ──────────────────────────────────────────────────

    def guardar_escaneo_planta(self, planta_id, imagen_bytes, resultado, confianza,
                                instrucciones, paso_numero, es_foto_seguimiento=False):
        try:
            img_b64 = self.comprimir_imagen_base64(imagen_bytes, max_size=800, quality=65)
            conexion = self.obtener_conexion()
            cursor = conexion.cursor()
            cursor.execute('''
                INSERT INTO escaneos_planta
                (planta_id, imagen_base64, resultado, confianza, instrucciones, paso_numero, es_foto_seguimiento, fecha_escaneo)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s) RETURNING id
            ''', (planta_id, img_b64, resultado, confianza, instrucciones, paso_numero, es_foto_seguimiento, datetime.now()))
            escaneo_id = cursor.fetchone()[0]
            # Actualizar estado de la planta
            cursor.execute('''
                UPDATE plantas SET estado_actual = %s, paso_tratamiento_actual = %s,
                fecha_ultimo_escaneo = %s WHERE id = %s
            ''', (resultado, paso_numero, datetime.now(), planta_id))
            conexion.commit()
            cursor.close()
            conexion.close()
            return {"exito": True, "escaneo_id": escaneo_id}
        except Exception as e:
            return {"exito": False, "mensaje": str(e)}

    def obtener_historial_planta(self, planta_id):
        try:
            conexion = self.obtener_conexion()
            cursor = conexion.cursor(cursor_factory=RealDictCursor)
            cursor.execute(
                'SELECT * FROM escaneos_planta WHERE planta_id = %s ORDER BY fecha_escaneo DESC',
                (planta_id,)
            )
            escaneos = cursor.fetchall()
            cursor.close()
            conexion.close()
            return {"exito": True, "escaneos": [
                {"id": e["id"], "imagen_base64": e["imagen_base64"],
                 "resultado": e["resultado"], "confianza": e["confianza"],
                 "instrucciones": e["instrucciones"], "paso_numero": e["paso_numero"],
                 "es_foto_seguimiento": e["es_foto_seguimiento"],
                 "tratamiento_completado": e["tratamiento_completado"],
                 "fecha_escaneo": e["fecha_escaneo"].isoformat()} for e in escaneos
            ]}
        except Exception as e:
            return {"exito": False, "mensaje": str(e)}

    def marcar_tratamiento_completado(self, escaneo_id):
        try:
            conexion = self.obtener_conexion()
            cursor = conexion.cursor()
            cursor.execute('UPDATE escaneos_planta SET tratamiento_completado = TRUE WHERE id = %s', (escaneo_id,))
            conexion.commit()
            cursor.close()
            conexion.close()
            return {"exito": True}
        except Exception as e:
            return {"exito": False, "mensaje": str(e)}

    def actualizar_notificaciones_planta(self, planta_id, activas):
        try:
            conexion = self.obtener_conexion()
            cursor = conexion.cursor()
            cursor.execute('UPDATE plantas SET notificaciones_activas = %s WHERE id = %s', (activas, planta_id))
            conexion.commit()
            cursor.close()
            conexion.close()
            return {"exito": True}
        except Exception as e:
            return {"exito": False, "mensaje": str(e)}


if __name__ == "__main__":
    try:
        db = BaseDatos()
        print("✅ Conexión exitosa a PostgreSQL")
    except Exception as e:
        print(f"❌ Error: {e}")
