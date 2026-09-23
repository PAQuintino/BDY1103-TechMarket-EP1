-- ============================================================
-- TECHMARKET SpA - EP1
-- TRIGGER DE TRAZABILIDAD Y BLOQUE DE EXCEPCIONES
-- Pruebas P2, P3, P4 y P5
-- ============================================================

SET SERVEROUTPUT ON;

-- ============================================================
-- 1. TRIGGER PARA TRAZABILIDAD (Prueba P5)
-- ============================================================

CREATE OR REPLACE TRIGGER trg_auditoria_beneficios
AFTER INSERT OR UPDATE ON bitacora_beneficios
FOR EACH ROW
DECLARE
    v_operacion VARCHAR2(10);
BEGIN
    IF INSERTING THEN
        v_operacion := 'INSERT';
    ELSIF UPDATING THEN
        v_operacion := 'UPDATE';
    END IF;

    INSERT INTO auditoria_beneficios (
        id_bitacora,
        operacion,
        usuario_bd,
        categoria_anterior,
        categoria_nueva,
        total_anterior,
        total_nuevo
    ) VALUES (
        :NEW.id_bitacora,
        v_operacion,
        USER, -- Usuario de BD actual
        :OLD.categoria_cliente,
        :NEW.categoria_cliente,
        :OLD.total_compras,
        :NEW.total_compras
    );
END;
/

-- ============================================================
-- 2. BLOQUE DE EXCEPCIONES Y CONTROL
--    Pruebas P2, P3 y P4
-- ============================================================

DECLARE
    -- Parámetros de entrada
    v_sucursal_id NUMBER := 999; -- P2: Sucursal inexistente
    v_fecha_inicio DATE := TO_DATE('01/09/2026', 'DD/MM/YYYY');
    v_fecha_fin DATE := TO_DATE('31/08/2026', 'DD/MM/YYYY');
    -- P3: Fecha fin antes de fecha inicio

    -- Variables para validación
    v_existe_sucursal NUMBER;
    v_total_ventas NUMBER;

    -- Excepciones definidas por usuario
    ex_periodo_invalido EXCEPTION;
    ex_sin_ventas EXCEPTION;

BEGIN
    -- Validación 1: Regla de negocio (P3)
    IF v_fecha_inicio > v_fecha_fin THEN
        RAISE ex_periodo_invalido;
    END IF;

    -- Validación 2: Excepción Oracle NO_DATA_FOUND (P2)
    SELECT id_sucursal
    INTO v_existe_sucursal
    FROM sucursal
    WHERE id_sucursal = v_sucursal_id;

    -- Validación 3: Regla de negocio, periodo sin ventas (P4)
    SELECT COUNT(*)
    INTO v_total_ventas
    FROM venta
    WHERE id_sucursal = v_sucursal_id
      AND fecha_venta BETWEEN v_fecha_inicio AND v_fecha_fin;

    IF v_total_ventas = 0 THEN
        RAISE ex_sin_ventas;
    END IF;

    DBMS_OUTPUT.PUT_LINE('Validaciones exitosas. Listo para procesar.');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE(
            'ERROR (Oracle): La sucursal ingresada (' ||
            v_sucursal_id ||
            ') no existe en el sistema.'
        );

    WHEN ex_periodo_invalido THEN
        DBMS_OUTPUT.PUT_LINE(
            'ERROR (Negocio): El periodo es invalido. ' ||
            'La fecha de inicio no puede ser posterior a la fecha de fin.'
        );

    WHEN ex_sin_ventas THEN
        DBMS_OUTPUT.PUT_LINE(
            'ERROR (Negocio): La sucursal ' ||
            v_sucursal_id ||
            ' no registro ventas en el periodo consultado.'
        );

    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(
            'ERROR NO ESPERADO: ' || SQLERRM
        );
END;
/
