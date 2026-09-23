/* ============================================================
   IMPORTANTE: Este codigo lo hice en OneCompiler(es casi lo mismo pero para que lo tengan en cuenta)

   PROYECTO: TechMarket SpA
   ASIGNATURA: BDY1103 - Taller de Base de Datos
   EVALUACION: EP1

   ARCHIVO: 02_DOCUMENTACION_TRIGGER_Y_BLOQUE_PLSQL
   RESPONSABLE: Danyer

   DESCRIPCION:
   Documentacion explicativa para el trigger de auditoria y el
   bloque anonimo PL/SQL encargados del control, validacion
   y manejo de excepciones en la asignacion de beneficios.

   COMPONENTES:
   - Trigger de Auditoria (TRG_AUDITORIA_BENEFICIOS)
   - Bloque PL/SQL (Control, Validaciones y Excepciones)

   REGLAS DE NEGOCIO:
   - Validacion estricta de parametros de entrada obligatorios.
   - Evaluacion de existencia previa del cliente.
   - Monto minimo requerido de $500.000 para asignacion de beneficio.
   - Auditoria automatica e imborrable de beneficios otorgados.

   TABLAS PRINCIPALES:
   - CLIENTE
   - VENTA
   - BITACORA_BENEFICIOS
   - AUDITORIA_BENEFICIOS

   INTEGRACION:
   Este codigo se integra directamente con las funciones desarrolladas
   por el resto del equipo.
   */


--TRIGGER DE AUDITORIA (TRAZABILIDAD DE BITACORA_BENEFICIOS)
CREATE OR REPLACE TRIGGER trg_auditoria_beneficios
AFTER INSERT ON bitacora_beneficios
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_beneficios (
        id_bitacora, operacion, usuario_bd, fecha_evento, categoria_nueva, total_nuevo
    ) VALUES (
        :NEW.id_bitacora, 'INSERT', USER, SYSDATE, :NEW.categoria_cliente, :NEW.total_compras
    );
    DBMS_OUTPUT.PUT_LINE('TRAZABILIDAD: Registro automatizado en AUDITORIA_BENEFICIOS para ID ' || :NEW.id_bitacora);
END;
/


-- BLOQUE PL/SQL DE CONTROL, VALIDACIONES Y EXCEPCIONES
DECLARE
    --Aqui solo tienen que cambiar v_id_cliente   NUMBER := 101; (pueden cambiarlo por 103 y 999)
    --Para que muestre todas las excepciones
    v_id_cliente   NUMBER := 101; 
    v_id_sucursal  NUMBER := 10;
    v_desde        DATE := DATE '2026-08-01';
    v_hasta        DATE := DATE '2026-08-31';
    
    v_nombre       VARCHAR2(120);
    v_cant_compras NUMBER := 0;
    v_total_monto  NUMBER := 0;
    
    -- Excepciones definidas por el usuario
    e_monto_insuficiente EXCEPTION;
    e_parametro_invalido EXCEPTION;
BEGIN
    -- Validaciones de entrada. Estos son Parametros obligatorios
    IF v_id_cliente IS NULL OR v_id_sucursal IS NULL OR v_desde IS NULL OR v_hasta IS NULL THEN
        RAISE e_parametro_invalido;
    END IF;

    IF v_desde > v_hasta THEN
        RAISE e_parametro_invalido;
    END IF;

    -- Validar existencia del cliente. Esta es la excepcion predefinida: NO_DATA_FOUND
    SELECT nombre 
    INTO v_nombre
    FROM cliente 
    WHERE id_cliente = v_id_cliente;

    -- Calcular compras acumuladas del periodo
    SELECT NVL(COUNT(*), 0), NVL(SUM(total), 0)
    INTO v_cant_compras, v_total_monto
    FROM venta
    WHERE id_cliente = v_id_cliente
      AND id_sucursal = v_id_sucursal
      AND fecha_venta BETWEEN v_desde AND v_hasta;

    --Regla de negocio y disparo de excepcion definida por el usuario
    IF v_total_monto < 500000 THEN
        RAISE e_monto_insuficiente;
    ELSE
        -- Insercion que activa la Trazabilidad (Trigger)
        INSERT INTO bitacora_beneficios (
            id_cliente, id_sucursal, periodo_desde, periodo_hasta,
            cantidad_compras, total_compras, categoria_cliente, porcentaje_beneficio, usuario_bd
        ) VALUES (
            v_id_cliente, v_id_sucursal, v_desde, v_hasta,
            v_cant_compras, v_total_monto, 'GOLD', 10.00, USER
        );
        
        DBMS_OUTPUT.PUT_LINE('EXITO: Beneficio asignado a ' || v_nombre || ' por total de $' || v_total_monto);
    END IF;

EXCEPTION
    -- Captura de validacion de entrada
    WHEN e_parametro_invalido THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Los parametros de entrada son nulos o el rango de fechas es invalido.');

    -- Captura de excepcion predefinida
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: El cliente ID ' || v_id_cliente || ' no existe en la BD.');
        
    -- Captura de excepcion definida por Usuario
    WHEN e_monto_insuficiente THEN
        DBMS_OUTPUT.PUT_LINE('RECHAZADO: Cliente ' || v_nombre || ' acumula $' || v_total_monto || ' (Minimo requerido: $500.000).');
        
    -- Captura generica
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR INESPERADO: Contactar al administrador DBA. ' || SQLERRM);
END;
/

-- CONSULTAS DE VERIFICACION
SELECT * FROM bitacora_beneficios;
SELECT * FROM auditoria_beneficios;

-- ============================================================
-- PRUEBA EXCEPCIÓN PREDEFINIDA: NO_DATA_FOUND
-- ============================================================

DECLARE

    v_cliente CLIENTE%ROWTYPE;

BEGIN

    -- Buscamos un cliente que NO existe
    SELECT *
    INTO v_cliente
    FROM CLIENTE
    WHERE id_cliente = 9999;

    -- Esta línea no se ejecutará si no existe el cliente
    DBMS_OUTPUT.PUT_LINE(
        'Cliente encontrado: ' || v_cliente.nombre
    );

EXCEPTION

    -- Excepción predefinida de Oracle
    WHEN NO_DATA_FOUND THEN

        DBMS_OUTPUT.PUT_LINE(
            'NO_DATA_FOUND: El cliente 9999 no existe.'
        );

END;
/

-- ============================================================
-- PRUEBA EXCEPCIÓN DEFINIDA POR EL USUARIO: PERÍODO INVÁLIDO
-- ============================================================
--ejepmlo triggers
BEGIN
    DBMS_OUTPUT.PUT_LINE(
        'Categoria: ' ||
        techmarket_beneficios.calcular_categoria(850000)
    );

    DBMS_OUTPUT.PUT_LINE(
        'Beneficio: ' ||
        techmarket_beneficios.calcular_beneficio(850000) ||
        '%'
    );
END;
/