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
    FUNCTION: CALCULAR_BENEFICIO
    ==================================================*/

   CREATE OR REPLACE FUNCTION calcular_categorias(
    p_total_comprado IN NUMBER
   )
   RETURN VARCHAR2
   IS
   BEGIN
        IF p_total_comprado < 300000 THEN 
            RETURN 'BRONZE';
        ELSIF p_total_comprado < 700000 THEN
            RETURN 'SILVER';
        ELSIF p_total_comprado <1500000 THEN
            RETURN 'GOLD';
        ELSE
            RETURN 'PLATINUM';
        END IF;
    END calcular_categoria;
    /

    /*==================================================
    FUNCTION: CALCULAR_BENEFICIO
    ==================================================*/

     CREATE OR REPLACE FUNCTION calcular_beneficios(
        p_total_comprado IN NUMBER
     )
     RETURN NUMBER
     IS
     BEGIN
        IF p_total_comprado < 300000 THEN 
            RETURN '5';
        ELSIF p_total_comprado BETWEEN 300000 AND 699999 THEN 
            RETURN 10;
        ELSIF p_total_comprado BETWEEN 700000 AND 1499999 THEN
            RETURN 15;
        ELSE
            RETURN 20;
        END IF;
    END calcular_beneficio;
    /

    /*==================================================
    FUNCTION: PROCESAR_BENEFICIO
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
    END procesar_beneficios;
    /
     