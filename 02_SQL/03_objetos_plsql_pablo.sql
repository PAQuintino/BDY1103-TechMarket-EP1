/* ============================================================
   PROYECTO: TechMarket SpA
   ASIGNATURA: BDY1103 - Taller de Base de Datos
   EVALUACIÓN: EP1

   ARCHIVO: 04_objetos_plsql.sql
   RESPONSABLE: Pablo

   DESCRIPCIÓN:
   Este archivo contiene los objetos PL/SQL utilizados para
   procesar la clasificación comercial de los clientes y
   determinar los beneficios correspondientes.

   COMPONENTES:
   - Functions
   - Procedure
   - Package

   REGLAS DE NEGOCIO:
   - BRONZE:   menor a $300.000 -> 5%
   - SILVER:   $300.000 a $699.999 -> 10%
   - GOLD:     $700.000 a $1.499.999 -> 15%
   - PLATINUM: $1.500.000 o más -> 20%

   TABLAS PRINCIPALES:
   - CLIENTE
   - VENTA
   - BITACORA_BENEFICIOS

   INTEGRACIÓN:
   La lógica de este archivo se integrará posteriormente
   con los cursores y excepciones desarrollados por los
   demás integrantes del equipo.

   ============================================================ */


/*==================================================
FUNCTION: CALCULAR_CATEGORIA
==================================================*/

CREATE OR REPLACE FUNCTION calcular_categoria(
    p_total_comprado IN NUMBER
)
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
/


/*==================================================
FUNCTION: CALCULAR_BENEFICIO
==================================================*/

CREATE OR REPLACE FUNCTION calcular_beneficio(
    p_total_comprado IN NUMBER
)
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
/


/*==================================================
PROCEDURE: PROCESAR_BENEFICIOS
==================================================*/

CREATE OR REPLACE PROCEDURE procesar_beneficios(
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

    FOR cliente IN (
        SELECT
            c.id_cliente,
            c.nombre
        FROM cliente c
        JOIN venta v
            ON c.id_cliente = v.id_cliente
        WHERE v.id_sucursal = p_id_sucursal
        AND v.fecha_venta BETWEEN p_fecha_desde AND p_fecha_hasta
        GROUP BY c.id_cliente, c.nombre
        ORDER BY c.id_cliente
    )
    LOOP

        SELECT
            COUNT(v.id_venta),
            NVL(SUM(v.total), 0)
        INTO
            v_cantidad_compras,
            v_total_comprado
        FROM venta v
        WHERE v.id_cliente = cliente.id_cliente
        AND v.id_sucursal = p_id_sucursal
        AND v.fecha_venta BETWEEN p_fecha_desde AND p_fecha_hasta;

        v_categoria := calcular_categoria(v_total_comprado);

        v_beneficio := calcular_beneficio(v_total_comprado);

        INSERT INTO BITACORA_BENEFICIOS (
            ID_CLIENTE,
            ID_SUCURSAL,
            PERIODO_DESDE,
            PERIODO_HASTA,
            CANTIDAD_COMPRAS,
            TOTAL_COMPRAS,
            CATEGORIA_CLIENTE,
            PORCENTAJE_BENEFICIO,
            FECHA_PROCESO,
            USUARIO_BD,
            FECHA_ACTUALIZACION
        )
        VALUES (
            cliente.id_cliente,
            p_id_sucursal,
            p_fecha_desde,
            p_fecha_hasta,
            v_cantidad_compras,
            v_total_comprado,
            v_categoria,
            v_beneficio,
            SYSDATE,
            USER,
            SYSDATE
        );

        DBMS_OUTPUT.PUT_LINE(
            'Cliente: ' || cliente.id_cliente ||
            ' | Compras: ' || v_cantidad_compras ||
            ' | Total: $' || v_total_comprado ||
            ' | Categoria: ' || v_categoria ||
            ' | Beneficio: ' || v_beneficio || '%'
        );

    END LOOP;

END procesar_beneficios;
/


/*==================================================
PACKAGE: TECHMARKET_BENEFICIOS
==================================================*/

CREATE OR REPLACE PACKAGE techmarket_beneficios AS

    FUNCTION calcular_categoria(
        p_total_comprado IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION calcular_beneficio(
        p_total_comprado IN NUMBER
    ) RETURN NUMBER;

    PROCEDURE procesar_beneficios(
        p_id_sucursal IN NUMBER,
        p_fecha_desde IN DATE,
        p_fecha_hasta IN DATE
    );

END techmarket_beneficios;
/


/*==================================================
PACKAGE BODY: TECHMARKET_BENEFICIOS
==================================================*/

CREATE OR REPLACE PACKAGE BODY techmarket_beneficios AS

    FUNCTION calcular_categoria(
        p_total_comprado IN NUMBER
    ) RETURN VARCHAR2
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


    FUNCTION calcular_beneficio(
        p_total_comprado IN NUMBER
    ) RETURN NUMBER
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

        FOR cliente IN (
            SELECT
                c.id_cliente,
                c.nombre
            FROM cliente c
            JOIN venta v
                ON c.id_cliente = v.id_cliente
            WHERE v.id_sucursal = p_id_sucursal
            AND v.fecha_venta BETWEEN p_fecha_desde AND p_fecha_hasta
            GROUP BY c.id_cliente, c.nombre
            ORDER BY c.id_cliente
        )
        LOOP

            SELECT
                COUNT(v.id_venta),
                NVL(SUM(v.total), 0)
            INTO
                v_cantidad_compras,
                v_total_comprado
            FROM venta v
            WHERE v.id_cliente = cliente.id_cliente
            AND v.id_sucursal = p_id_sucursal
            AND v.fecha_venta BETWEEN p_fecha_desde AND p_fecha_hasta;

            v_categoria := calcular_categoria(v_total_comprado);

            v_beneficio := calcular_beneficio(v_total_comprado);

            INSERT INTO BITACORA_BENEFICIOS (
                ID_CLIENTE,
                ID_SUCURSAL,
                PERIODO_DESDE,
                PERIODO_HASTA,
                CANTIDAD_COMPRAS,
                TOTAL_COMPRAS,
                CATEGORIA_CLIENTE,
                PORCENTAJE_BENEFICIO,
                FECHA_PROCESO,
                USUARIO_BD,
                FECHA_ACTUALIZACION
            )
            VALUES (
                cliente.id_cliente,
                p_id_sucursal,
                p_fecha_desde,
                p_fecha_hasta,
                v_cantidad_compras,
                v_total_comprado,
                v_categoria,
                v_beneficio,
                SYSDATE,
                USER,
                SYSDATE
            );

            DBMS_OUTPUT.PUT_LINE(
                'Cliente: ' || cliente.id_cliente ||
                ' | Compras: ' || v_cantidad_compras ||
                ' | Total: $' || v_total_comprado ||
                ' | Categoria: ' || v_categoria ||
                ' | Beneficio: ' || v_beneficio || '%'
            );

        END LOOP;

    END procesar_beneficios;

END techmarket_beneficios;
/

--EJEMPLO CATEGORIAS
SELECT calcular_categoria(250000) FROM dual;
--EJEMPLO BENEFICIO
SELECT calcular_beneficio(250000) FROM dual;