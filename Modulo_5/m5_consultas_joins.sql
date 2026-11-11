-- RetailPro / TechStore - Modulo 5
-- Pre-entrega 5: Consultas con JOINs para el proyecto
-- Motor: Microsoft SQL Server (SSMS)
-- Base de referencia: Ventas_Tech_DB (Modulo 3)
-- IMPORTANTE: en este modelo, id_venta identifica filas de ventas;
-- no necesariamente pedidos comerciales con varios productos.
-- El modelo incluye ciudad del cliente y categoria del producto, pero no canal.

USE Ventas_Tech_DB;
GO

-- ============================================================
-- CONSULTA 1: Vista base del proyecto (INNER JOIN)
-- Proposito: enriquecer cada venta con el cliente, su ciudad,
-- el producto y la categoria para analizar en Power BI.
-- ============================================================
SELECT
    v.id_venta,
    v.fecha_venta,
    c.id_cliente,
    c.nombre AS nombre_cliente,
    c.email AS email_cliente,
    c.ciudad AS ciudad_cliente,
    p.id_producto,
    p.nombre_producto,
    cat.nombre_categoria,
    v.cantidad,
    v.precio_unitario,
    CAST(v.cantidad * v.precio_unitario AS DECIMAL(12,2)) AS total_venta
FROM ventas AS v
INNER JOIN clientes AS c
    ON v.id_cliente = c.id_cliente
INNER JOIN productos AS p
    ON v.id_producto = p.id_producto
INNER JOIN categorias AS cat
    ON p.id_categoria = cat.id_categoria
ORDER BY v.fecha_venta, v.id_venta;
-- Hallazgo: las 10 ventas del ejemplo quedan relacionadas con su
-- cliente, producto y categoria; la facturacion total suma 6444.00.

-- ============================================================
-- CONSULTA 2: Clientes sin ventas (LEFT JOIN)
-- Proposito: identificar clientes registrados que aun no compraron,
-- para que el equipo de CRM pueda contactarlos.
-- ============================================================
SELECT
    c.nombre AS nombre_cliente,
    c.email,
    c.fecha_registro
FROM clientes AS c
LEFT JOIN ventas AS v
    ON c.id_cliente = v.id_cliente
WHERE v.id_venta IS NULL
ORDER BY c.nombre;
-- Hallazgo: 0 de los 5 clientes registrados aparecen sin ventas.
-- Con estos datos, CRM no tiene clientes sin compra para recuperar.

-- ============================================================
-- CONSULTA 3: Productos sin ventas (LEFT JOIN)
-- Proposito: detectar articulos del catalogo sin movimiento,
-- para orientar la revision del area de producto.
-- ============================================================
SELECT
    p.nombre_producto,
    cat.nombre_categoria AS categoria,
    p.precio
FROM productos AS p
INNER JOIN categorias AS cat
    ON p.id_categoria = cat.id_categoria
LEFT JOIN ventas AS v
    ON p.id_producto = v.id_producto
WHERE v.id_venta IS NULL
ORDER BY p.nombre_producto;
-- Hallazgo: 0 de los 6 productos del catalogo aparecen sin ventas.
-- No hay articulos totalmente inactivos en esta muestra de marzo.

-- ============================================================
-- CONSULTA 4: Consolidado por origen (UNION ALL)
-- Proposito: comparar la facturacion de dos periodos excluyentes.
-- La columna 'canal' se crea como texto en cada SELECT: NO existe
-- en ventas. Sus etiquetas representan periodos, NO canales reales.
-- ============================================================
SELECT
    canal,
    SUM(total) AS total_canal
FROM (
    SELECT
        fecha_venta,
        cantidad * precio_unitario AS total,
        '05-10 marzo' AS canal
    FROM ventas
    WHERE fecha_venta >= '2024-03-05'
      AND fecha_venta <  '2024-03-11'

    UNION ALL

    SELECT
        fecha_venta,
        cantidad * precio_unitario AS total,
        '11-15 marzo' AS canal
    FROM ventas
    WHERE fecha_venta >= '2024-03-11'
      AND fecha_venta <  '2024-03-16'
) AS consolidado
GROUP BY canal
ORDER BY total_canal DESC;
-- Hallazgo: del 5 al 10 de marzo se facturaron 3620.00, frente
-- a 2824.00 del 11 al 15; la primera etapa genero 796.00 mas.
-- Son dos periodos, no ventas Online o Presenciales: el dato de
-- canal real no esta disponible en la base de este modulo.
