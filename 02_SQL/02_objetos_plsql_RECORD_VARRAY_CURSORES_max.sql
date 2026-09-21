/* ============================================================
   PROYECTO: TechMarket SpA
   ASIGNATURA: BDY1103 - Taller de Base de Datos
   EVALUACIÓN: EP1

   ARCHIVO: 02_objetos_plsql_RECORD_VARRAY_CURSORES_max.sql
   RESPONSABLE: Max

   DESCRIPCIÓN:
   Este archivo contiene los bloques PL/SQL correspondientes a
   RECORD, VARRAY y cursores parametrizados con LOOP anidado.

   INTEGRACIÓN:
   Este archivo utiliza las funciones calcular_categoria y
   calcular_beneficio creadas en 04_objetos_plsql.sql.

   ============================================================ */


-- ============================================================
-- 1. RECORD + VARRAY
-- ============================================================

DECLARE

    TYPE cliente_record IS RECORD (
        id_cliente       CLIENTE.ID_CLIENTE%TYPE,
        nombre_cliente   CLIENTE.NOMBRE%TYPE,
        cantidad_compras NUMBER,
        total_comprado   NUMBER,
        categoria        VARCHAR2(20),
        beneficio        NUMBER
    );

    v_cliente cliente_record;

    TYPE beneficios_varray IS VARRAY(4) OF NUMBER;
    v_beneficios beneficios_varray := beneficios_varray(5, 10, 15, 20);

BEGIN

    SELECT
        c.id_cliente,
        c.nombre,
        COUNT(v.id_venta),
        NVL(SUM(v.total), 0)
    INTO
        v_cliente.id_cliente,
        v_cliente.nombre_cliente,
        v_cliente.cantidad_compras,
        v_cliente.total_comprado
    FROM cliente c
    LEFT JOIN venta v
        ON c.id_cliente = v.id_cliente
    WHERE c.id_cliente = 101
    GROUP BY c.id_cliente, c.nombre;

    v_cliente.categoria := calcular_categoria(v_cliente.total_comprado);
    v_cliente.beneficio := calcular_beneficio(v_cliente.total_comprado);

    DBMS_OUTPUT.PUT_LINE('ID Cliente: ' || v_cliente.id_cliente);
    DBMS_OUTPUT.PUT_LINE('Nombre: ' || v_cliente.nombre_cliente);
    DBMS_OUTPUT.PUT_LINE('Cantidad compras: ' || v_cliente.cantidad_compras);
    DBMS_OUTPUT.PUT_LINE('Total comprado: $' || v_cliente.total_comprado);
    DBMS_OUTPUT.PUT_LINE('Categoria: ' || v_cliente.categoria);
    DBMS_OUTPUT.PUT_LINE('Beneficio: ' || v_cliente.beneficio || '%');

    DBMS_OUTPUT.PUT_LINE(
        'Beneficios disponibles: ' ||
        v_beneficios(1) || '%, ' ||
        v_beneficios(2) || '%, ' ||
        v_beneficios(3) || '%, ' ||
        v_beneficios(4) || '%'
    );

END;
/


-- ============================================================
-- 2. CURSORES PARAMETRIZADOS + LOOP ANIDADO
-- ============================================================

DECLARE

    v_id_sucursal NUMBER := 10;
    v_fecha_desde DATE := DATE '2026-08-01';
    v_fecha_hasta DATE := DATE '2026-08-31';


    -- Cursor externo: obtiene los clientes de la sucursal
    -- y período indicado.
    CURSOR cur_clientes(
        p_id_sucursal NUMBER,
        p_fecha_desde DATE,
        p_fecha_hasta DATE
    )
    IS
        SELECT DISTINCT
            c.id_cliente,
            c.nombre
        FROM cliente c
        JOIN venta v
            ON c.id_cliente = v.id_cliente
        WHERE v.id_sucursal = p_id_sucursal
        AND v.fecha_venta BETWEEN p_fecha_desde AND p_fecha_hasta
        ORDER BY c.id_cliente;


    -- Cursor interno: obtiene las ventas del cliente
    -- que está recorriendo el cursor externo.
    CURSOR cur_ventas(
        p_id_cliente NUMBER,
        p_id_sucursal NUMBER,
        p_fecha_desde DATE,
        p_fecha_hasta DATE
    )
    IS
        SELECT
            id_venta,
            fecha_venta,
            total
        FROM venta
        WHERE id_cliente = p_id_cliente
        AND id_sucursal = p_id_sucursal
        AND fecha_venta BETWEEN p_fecha_desde AND p_fecha_hasta
        ORDER BY fecha_venta;


    v_cantidad_compras NUMBER;
    v_total_comprado NUMBER;

BEGIN

    -- LOOP externo: recorre los clientes.
    FOR cliente IN cur_clientes(
        v_id_sucursal,
        v_fecha_desde,
        v_fecha_hasta
    )
    LOOP

        v_cantidad_compras := 0;
        v_total_comprado := 0;

        DBMS_OUTPUT.PUT_LINE('--------------------------------');
        DBMS_OUTPUT.PUT_LINE(
            'Cliente: ' || cliente.id_cliente ||
            ' - ' || cliente.nombre
        );

        -- LOOP interno: recorre las ventas del cliente.
        FOR venta IN cur_ventas(
            cliente.id_cliente,
            v_id_sucursal,
            v_fecha_desde,
            v_fecha_hasta
        )
        LOOP

            v_cantidad_compras := v_cantidad_compras + 1;
            v_total_comprado := v_total_comprado + venta.total;

            DBMS_OUTPUT.PUT_LINE(
                '  Venta: ' || venta.id_venta ||
                ' | Fecha: ' ||
                TO_CHAR(venta.fecha_venta, 'DD/MM/YYYY') ||
                ' | Total: $' || venta.total
            );

        END LOOP;

        DBMS_OUTPUT.PUT_LINE(
            'Cantidad compras: ' || v_cantidad_compras
        );

        DBMS_OUTPUT.PUT_LINE(
            'Total comprado: $' || v_total_comprado
        );

        DBMS_OUTPUT.PUT_LINE(
            'Categoria: ' ||
            calcular_categoria(v_total_comprado)
        );

        DBMS_OUTPUT.PUT_LINE(
            'Beneficio: ' ||
            calcular_beneficio(v_total_comprado) || '%'
        );

    END LOOP;

END;
/
