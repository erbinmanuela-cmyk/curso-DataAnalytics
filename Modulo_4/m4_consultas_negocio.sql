-- RetailPro / TechStore | Modulo 4: Consultas SQL de negocio
-- Motor: Microsoft SQL Server | Base: Ventas_Tech_DB (Modulo 3)
-- Las consultas utilizan exclusivamente la tabla ventas.
-- Nota: en este esquema cada fila de ventas se toma como una operacion
-- para el ejercicio. No existe un id_pedido que agrupe varios productos.

USE Ventas_Tech_DB;
GO

-- =============================================================
-- CONSULTA 1 - RESUMEN EJECUTIVO MENSUAL
-- Agrupamos por anio y mes para no mezclar marzos de distintos anios.
-- =============================================================
SELECT
    YEAR(fecha_venta) AS anio,
    MONTH(fecha_venta) AS mes,
    SUM(cantidad * precio_unitario) AS total_facturado,
    COUNT(*) AS cantidad_pedidos,
    CAST(SUM(cantidad * precio_unitario) / NULLIF(COUNT(*), 0) AS DECIMAL(12,2)) AS ticket_promedio
FROM ventas
GROUP BY YEAR(fecha_venta), MONTH(fecha_venta)
ORDER BY anio, mes;
GO

-- =============================================================
-- CONSULTA 2 - TOP 5 PRODUCTOS POR FACTURACION
-- =============================================================
SELECT TOP 5
    id_producto,
    SUM(cantidad) AS unidades_vendidas,
    SUM(cantidad * precio_unitario) AS total_facturado
FROM ventas
GROUP BY id_producto
ORDER BY total_facturado DESC, id_producto ASC;
GO

-- =============================================================
-- CONSULTA 3 - CLIENTES RECURRENTES
-- COUNT(*) cuenta registros de venta del modelo de M3.
-- =============================================================
SELECT
    id_cliente,
    COUNT(*) AS cantidad_pedidos,
    SUM(cantidad * precio_unitario) AS total_gastado
FROM ventas
GROUP BY id_cliente
HAVING COUNT(*) > 1
ORDER BY cantidad_pedidos DESC, total_gastado DESC, id_cliente ASC;
GO

-- =============================================================
-- CONSULTA 4 - PRODUCTOS SOBRE O BAJO EL PROMEDIO
-- El promedio se calcula sobre la FACTURACION TOTAL de cada producto,
-- no sobre cada registro individual de la tabla ventas.
-- =============================================================
WITH facturacion_por_producto AS (
    SELECT
        id_producto,
        SUM(cantidad * precio_unitario) AS total_facturado
    FROM ventas
    GROUP BY id_producto
)
SELECT
    f.id_producto,
    f.total_facturado,
    CASE
        WHEN f.total_facturado > (
            SELECT AVG(total_facturado)
            FROM facturacion_por_producto
        ) THEN 'Por encima'
        ELSE 'Por debajo'
    END AS comparacion_con_promedio
FROM facturacion_por_producto AS f
ORDER BY f.total_facturado DESC, f.id_producto ASC;
GO

-- =============================================================
-- BLOQUE DE CIERRE - 3 HALLAZGOS (datos originales de M3)
-- 1) En marzo de 2024 se registran 10 operaciones por un total de
--    6444.00 y un ticket promedio de 644.40 por registro.
-- 2) El producto 1 factura 3600.00: aproximadamente el 55.87%
--    de los 6444.00 facturados en el conjunto de datos.
-- 3) Solo los productos 1 (3600.00) y 3 (1350.00) superan
--    el promedio de facturacion por producto, que es 1074.00.
-- =============================================================
