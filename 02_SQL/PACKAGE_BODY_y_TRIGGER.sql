
-- con esto puedes consultar, porque yo lo hice en one compiler y ahi no puedo tomar las cap 
-- si pueden correr el codigo y tomar las caps, se los agradecerias

SET SERVEROUTPUT ON;

-- Limpiar registros anteriores para una prueba limpia
DELETE FROM auditoria_beneficios;
DELETE FROM bitacora_beneficios;
COMMIT;

-- Ejecutar el procedimiento del paquete que disparará el trigger compuesto
BEGIN
    techmarket_beneficios.procesar_beneficios(
        10,
        DATE '2026-08-01',
        DATE '2026-08-31'
    );
END;
/

-- Consultar los resultados para evidenciar el funcionamiento en las tablas
SELECT * FROM bitacora_beneficios;
SELECT * FROM auditoria_beneficios;


-- codigo que pide el profe 

CREATE OR REPLACE PACKAGE BODY techmarket_beneficios AS
    -- esto es lo que pide el profe
    -- Función auxiliar interna para formatear montos monetarios. 
    -- Al no estar declarada en la especificación (AS), es estrictamente privada.

    FUNCTION fn_formatear_monto_privado(p_monto IN NUMBER) 
    RETURN VARCHAR2 
    IS
    BEGIN
        -- Retorna el monto formateado con símbolo de peso y separadores de miles
        RETURN '$' || TO_CHAR(p_monto, 'FM999g999g999');
    END fn_formatear_monto_privado;

    -- FUNCIÓN: calcular_categoria
    -- Evalúa el total de compras para clasificar al cliente según las reglas del negocio.
    
    FUNCTION calcular_categoria(p_total_comprado IN NUMBER)
    RETURN VARCHAR2
    IS
    BEGIN
        IF p_total_comprado < 300000 THEN
            RETURN 'BRONZE';
        ELSIF p_total_comprado < 700000 THEN
            RETURN 'SILVER';
        ELSIF p_total_comprado < 1500000 THEN
            RETURN 'GOLD';
        ELSE
            RETURN 'PLATINUM';
        END IF;
    END calcular_categoria;

    -- FUNCIÓN: calcular_beneficio
    -- Retorna el porcentaje de beneficio aplicable según el volumen de compras.

    FUNCTION calcular_beneficio(p_total_comprado IN NUMBER)
    RETURN NUMBER
    IS
    BEGIN
        IF p_total_comprado < 300000 THEN
            RETURN 5;
        ELSIF p_total_comprado < 700000 THEN
            RETURN 10;
        ELSIF p_total_comprado < 1500000 THEN
            RETURN 15;
        ELSE
            RETURN 20;
        END IF;
    END calcular_beneficio;

  
    -- PROCEDIMIENTO: procesar_beneficios
    -- Núcleo operativo: recorre los clientes con compras en una sucursal y período 
    -- determinado, calcula sus métricas y registra el resultado en la bitácora.

    PROCEDURE procesar_beneficios(
        p_id_sucursal IN NUMBER,
        p_fecha_desde IN DATE,
        p_fecha_hasta IN DATE
    )
    IS
        v_total_comprado NUMBER;
        v_cantidad_compras NUMBER;
        v_categoria VARCHAR2(20);
        v_beneficio NUMBER;
    BEGIN
        -- Cursor que selecciona los clientes únicos con ventas en la sucursal y fechas dadas
        FOR cliente IN (
            SELECT c.id_cliente, c.nombre
            FROM cliente c
            JOIN venta v ON c.id_cliente = v.id_cliente
            WHERE v.id_sucursal = p_id_sucursal
            AND v.fecha_venta BETWEEN p_fecha_desde AND p_fecha_hasta
            GROUP BY c.id_cliente, c.nombre
            ORDER BY c.id_cliente
        )
        LOOP
            -- Consulta para consolidar el total monetario y la cantidad de transacciones
            SELECT COUNT(v.id_venta), NVL(SUM(v.total), 0)
            INTO v_cantidad_compras, v_total_comprado
            FROM venta v
            WHERE v.id_cliente = cliente.id_cliente
            AND v.id_sucursal = p_id_sucursal
            AND v.fecha_venta BETWEEN p_fecha_desde AND p_fecha_hasta;

            -- Invocación de las funciones internas del paquete para categoría y beneficio
            v_categoria := calcular_categoria(v_total_comprado);
            v_beneficio := calcular_beneficio(v_total_comprado);

            -- Inserción del registro consolidado en la tabla de bitácora
            INSERT INTO bitacora_beneficios (
                id_cliente, id_sucursal, periodo_desde, periodo_hasta,
                cantidad_compras, total_compras, categoria_cliente,
                porcentaje_beneficio, fecha_proceso, usuario_bd, fecha_actualizacion
            )
            VALUES (
                cliente.id_cliente, p_id_sucursal, p_fecha_desde, p_fecha_hasta,
                v_cantidad_compras, v_total_comprado, v_categoria,
                v_beneficio, SYSDATE, USER, SYSDATE
            );
        END LOOP;
    END procesar_beneficios;

END techmarket_beneficios;
/


-- este es el otro codigo que pide el profe 

CREATE OR REPLACE TRIGGER trg_auditoria_beneficios
FOR INSERT OR UPDATE ON bitacora_beneficios
COMPOUND TRIGGER

      -- DESCRIPCIÓN: Trigger compuesto de auditoría para la tabla bitacora_beneficios.
      -- Registra los cambios a nivel de fila (AFTER EACH ROW) utilizando pseudorregistros 
      -- :OLD y :NEW, y emite un resumen consolidado a nivel de sentencia (AFTER STATEMENT).
    

    -- 1. Variable global a NIVEL DE SENTENCIA (mantiene el conteo durante toda la transacción)
     v_total_auditados NUMBER := 0;

    -- 2. Acción a NIVEL DE FILA (Row-level): se ejecuta de forma iterativa por cada registro afectado
    AFTER EACH ROW IS
        v_operacion VARCHAR2(10);
    BEGIN
        -- Determino si la operación actual es una inserción o una actualización
        IF INSERTING THEN
            v_operacion := 'INSERT';
        ELSIF UPDATING THEN
            v_operacion := 'UPDATE';
        END IF;

        -- Inserto el detalle de la auditoría capturando los estados anteriores y nuevos
        INSERT INTO auditoria_beneficios (
            id_bitacora,
            operacion,
            usuario_bd,
            fecha_evento,
            categoria_anterior,
            categoria_nueva,
            total_anterior,
            total_nuevo
        )
        VALUES (
            :NEW.id_bitacora,
            v_operacion,
            USER,
            SYSDATE,
            :OLD.categoria_cliente,
            :NEW.categoria_cliente,
            :OLD.total_compras,
            :NEW.total_compras
        );

        -- Incremento el contador global por cada fila procesada exitosamente en el bloque
        v_total_auditados := v_total_auditados + 1;
    END AFTER EACH ROW;

    -- 3. Acción a NIVEL DE SENTENCIA (Statement-level resumen): se ejecuta una sola vez al finalizar la sentencia
    AFTER STATEMENT IS
    BEGIN
        -- Muestro por consola el mensaje resumen con la cantidad total de registros auditados
        DBMS_OUTPUT.PUT_LINE(
            'TRAZABILIDAD [SENTENCIA]: Se auditaron exitosamente ' || v_total_auditados || ' registro(s) en esta operación.'
        );
    END AFTER STATEMENT;

END trg_auditoria_beneficios;
/

