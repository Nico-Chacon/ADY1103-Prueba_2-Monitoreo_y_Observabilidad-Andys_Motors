-- ============================================
<<<<<<< HEAD
-- AndysMotors - Base de Datos
-- Comercializacion presencial de vehiculos nuevos y usados
-- Tablas: vehiculos (catalogo/stock), visitas (agendamiento),
--         contactos (solicitudes de contacto)
-- ============================================

CREATE DATABASE IF NOT EXISTS andysmotors CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE andysmotors;

CREATE TABLE IF NOT EXISTS vehiculos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    marca VARCHAR(60) NOT NULL,
    modelo VARCHAR(80) NOT NULL,
    anio SMALLINT NOT NULL,
    tipo ENUM('nuevo','usado') NOT NULL,
    carroceria VARCHAR(40),
    combustible VARCHAR(30),
    transmision VARCHAR(30),
    kilometraje INT NOT NULL DEFAULT 0,
    color VARCHAR(40),
    precio DECIMAL(12,0) NOT NULL,
    sucursal VARCHAR(60) NOT NULL,
    estado ENUM('disponible','reservado','vendido') NOT NULL DEFAULT 'disponible',
    descripcion TEXT,
=======
-- FreshBox SpA - Base de Datos (EP1)
-- Evaluacion Parcial 1 - ARY1102
-- ============================================

CREATE DATABASE IF NOT EXISTS freshbox;
USE freshbox;

CREATE TABLE IF NOT EXISTS productos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    categoria VARCHAR(100),
    imagen_url VARCHAR(500),
>>>>>>> 7c0071f9c8f6cd60faeeff7d71a3c4f1c7901024
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

<<<<<<< HEAD
CREATE TABLE IF NOT EXISTS visitas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vehiculo_id INT NOT NULL,
    nombre_cliente VARCHAR(120) NOT NULL,
    email VARCHAR(150) NOT NULL,
    telefono VARCHAR(30) NOT NULL,
    sucursal VARCHAR(60) NOT NULL,
    fecha_visita DATETIME NOT NULL,
    estado ENUM('agendada','cancelada','realizada') NOT NULL DEFAULT 'agendada',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehiculo_id) REFERENCES vehiculos(id)
);

CREATE TABLE IF NOT EXISTS contactos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vehiculo_id INT NULL,
    nombre VARCHAR(120) NOT NULL,
    email VARCHAR(150) NOT NULL,
    telefono VARCHAR(30) NOT NULL,
    mensaje TEXT,
    canal_preferido ENUM('telefono','email','whatsapp') NOT NULL DEFAULT 'telefono',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehiculo_id) REFERENCES vehiculos(id)
);

INSERT INTO vehiculos (marca, modelo, anio, tipo, carroceria, combustible, transmision, kilometraje, color, precio, sucursal, estado, descripcion) VALUES
('Toyota',  'Corolla Cross XLI', 2025, 'nuevo', 'SUV',       'Hibrido',  'Automatica', 0,     'Blanco perla', 24990000, 'Las Condes',      'disponible', 'SUV hibrido 0 km, garantia de fabrica 3 anios, Apple CarPlay y Android Auto.'),
('Hyundai', 'Tucson GLS',        2025, 'nuevo', 'SUV',       'Bencina',  'Automatica', 0,     'Gris grafito', 26490000, 'Providencia',     'disponible', 'SUV familiar 0 km con 6 airbags y camara de retroceso.'),
('Kia',     'Morning EX',        2024, 'nuevo', 'Hatchback', 'Bencina',  'Mecanica',   0,     'Rojo',         10990000, 'Santiago Centro', 'disponible', 'Citycar economico, ideal para ciudad. Entrega inmediata.'),
('Chevrolet','Sail LT',          2021, 'usado', 'Sedan',     'Bencina',  'Mecanica',   48500, 'Plata',         7990000,  'Maipu',           'disponible', 'Un solo dueno, mantenciones al dia en servicio oficial.'),
('Nissan',  'Qashqai Advance',   2020, 'usado', 'SUV',       'Bencina',  'Automatica', 62300, 'Azul',          13490000, 'Las Condes',      'reservado',  'Reservado por cliente, disponible si no se concreta el pago.'),
('Suzuki',  'Swift GL',          2022, 'usado', 'Hatchback', 'Bencina',  'Mecanica',   31800, 'Negro',         9490000,  'Providencia',     'disponible', 'Muy buen estado, revision tecnica y permiso de circulacion vigentes.'),
('Ford',    'Ranger XLT 4x4',    2023, 'usado', 'Camioneta', 'Diesel',   'Automatica', 27400, 'Blanco',        23990000, 'Santiago Centro', 'disponible', 'Doble cabina 4x4, ideal para trabajo y fines de semana.'),
('Mazda',   'CX-5 R',            2022, 'usado', 'SUV',       'Bencina',  'Automatica', 39900, 'Rojo',          17990000, 'Maipu',           'disponible', 'Techo panoramico, asientos de cuero, unico dueno.');

-- Datos de ejemplo para que la consulta de visitas/contactos tenga contenido
INSERT INTO visitas (vehiculo_id, nombre_cliente, email, telefono, sucursal, fecha_visita, estado) VALUES
(1, 'Cliente Demo', 'demo@andysmotors.cl', '+56911111111', 'Las Condes', DATE_ADD(CURDATE(), INTERVAL 2 DAY) + INTERVAL 11 HOUR, 'agendada');
=======
INSERT INTO productos (nombre, descripcion, precio, stock, categoria) VALUES
('Manzana organica 1kg', 'Manzanas rojas organicas, cultivo sin pesticidas, bolsa 1 kilogramo', 3490.00, 120, 'Frutas'),
('Lechuga hidroponica', 'Lechuga fresca cultivada en sistema hidroponico, libre de tierra', 1990.00, 80, 'Verduras'),
('Granola artesanal 500g', 'Granola con avena, miel, almendras y arandanos, sin azucar refinada', 4990.00, 60, 'Snacks'),
('Jugo natural naranja 1L', 'Jugo 100% natural de naranja, sin preservantes ni colorantes', 2990.00, 100, 'Bebidas'),
('Mix frutos secos 250g', 'Mezcla de almendras, nueces, castanas de caju y pasas organicas', 5490.00, 45, 'Snacks');

-- 2026 - Disenador asignatura: Ignacio A. Pastenet M.
>>>>>>> 7c0071f9c8f6cd60faeeff7d71a3c4f1c7901024
