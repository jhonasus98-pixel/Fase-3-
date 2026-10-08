% RETO 3 - ALGORITMO DE CONTROL Y CARGAS
% Estudiante: Johon Estrada
% Curso: Software para Ingenieria - 203036
% Simulacion de control de una micro-red hibrida durante 24 horas

clc;
clear;
close all;

% ---------------------------------------------------------
% 1. CONFIGURACION INICIAL
% ---------------------------------------------------------

% Vector correspondiente a las 24 horas del dia.
horas = 1:24;

% Factor de prueba de estres sobre la demanda.
% 1 = escenario real del Reto 2.
% 2.5 = prueba que permite verificar las rutas de Alerta y Emergencia.
FACTOR_DEMANDA = 1;

% ---------------------------------------------------------
% 2. DATOS DEL RETO 2
% ---------------------------------------------------------
% Los vectores estan en kW. Como cada intervalo dura 1 hora,
% la potencia en kW equivale a energia en kWh (kW x 1 h).

% Generacion solar en kW.
solar = [0 0 0 0 0 5 10 15 20 23 24 25 ...
         24 20 16 12 8 4 0 0 0 0 0 0];

% Generacion eolica en kW.
eolica = [8 10 7 12 9 11 13 8 14 10 12 15 ...
          9 13 11 7 10 14 12 9 6 11 8 10];

% Demanda total de la comunidad en kW (se aplica el factor de prueba).
demanda = [3 3 4 2 3 7 8 9 8 9 10 10 ...
           9 8 7 9 10 9 15 14 15 4 3 4] * FACTOR_DEMANDA;

% ---------------------------------------------------------
% 3. CALCULO DE LA GENERACION HIBRIDA
% ---------------------------------------------------------

% Se suman la generacion solar y eolica.
generacion_total = solar + eolica;

% ---------------------------------------------------------
% 4. CALCULO DEL BALANCE ENERGETICO
% ---------------------------------------------------------

% Balance positivo: existe excedente energetico.
% Balance negativo: existe deficit energetico.
balance = generacion_total - demanda;

% ---------------------------------------------------------
% 5. CONFIGURACION DE LA BATERIA
% ---------------------------------------------------------

% Capacidad total de la bateria en kWh.
capacidad_bateria = 100;

% Estado de carga inicial de la bateria (%).
SOC_inicial = 50;

% Variable que almacenara el SOC de cada hora.
SOC = zeros(1,24);

% Se establece el estado inicial.
SOC_actual = SOC_inicial;

% ---------------------------------------------------------
% 6. VARIABLES PARA EL ESTADO DE LAS CARGAS
% ---------------------------------------------------------

% 1 = servicio activo
% 0 = servicio desconectado
escuela = zeros(1,24);
bombeo = zeros(1,24);
alumbrado = zeros(1,24);

% Etiquetas para el reporte: posicion 1 = suspendido, posicion 2 = activo.
estados = {'SUSPENDIDO', 'ACTIVO'};

% Etiqueta de la ruta de operacion aplicada en cada hora.
ruta = cell(1,24);

% ---------------------------------------------------------
% 7. CICLO DE SIMULACION DE 24 HORAS
% ---------------------------------------------------------

fprintf('=========== REPORTE HORARIO DEL CONTROLADOR ===========\n');

for i = 1:24

    % -----------------------------------------------------
    % ESCENARIO DE SUPERAVIT
    % -----------------------------------------------------

    if balance(i) >= 0

        % Se calcula el excedente de energia.
        excedente = balance(i);

        % El excedente se utiliza para cargar la bateria.
        SOC_actual = SOC_actual + ...
            (excedente / capacidad_bateria) * 100;

        % Se limita el SOC al maximo permitido del 100%.
        if SOC_actual > 100
            SOC_actual = 100;
        end

        % En superavit todos los servicios permanecen activos
        % de forma nominal, sin importar el nivel de SOC.
        escuela(i) = 1;
        bombeo(i) = 1;
        alumbrado(i) = 1;
        ruta{i} = 'Superavit';

    % -----------------------------------------------------
    % ESCENARIO DE DEFICIT
    % -----------------------------------------------------

    else

        % Se calcula la energia faltante.
        faltante = abs(balance(i));

        % La bateria suministra la energia faltante.
        SOC_actual = SOC_actual - ...
            (faltante / capacidad_bateria) * 100;

        % Se limita el SOC al minimo permitido del 0%.
        if SOC_actual < 0
            SOC_actual = 0;
        end

        % -------------------------------------------------
        % LOGICA DE CONTROL DE CARGAS (LOAD SHEDDING)
        % Solo se aplica en deficit, con el nuevo SOC.
        % -------------------------------------------------

        % La escuela siempre tiene prioridad critica.
        escuela(i) = 1;

        if SOC_actual > 40
            % RUTA SEGURA: SOC > 40%
            % Todos los servicios permanecen activos.
            bombeo(i) = 1;
            alumbrado(i) = 1;
            ruta{i} = 'Deficit - Ruta SEGURA';

        elseif SOC_actual > 20
            % RUTA DE ALERTA: 20% < SOC <= 40%
            % Se desconecta el alumbrado publico (baja prioridad).
            bombeo(i) = 1;
            alumbrado(i) = 0;
            ruta{i} = 'Deficit - Ruta de ALERTA';

        else
            % RUTA DE EMERGENCIA: SOC <= 20%
            % Se mantiene unicamente la escuela.
            bombeo(i) = 0;
            alumbrado(i) = 0;
            ruta{i} = 'Deficit - Ruta de EMERGENCIA';
        end

    end

    % Se guarda el SOC correspondiente a la hora.
    SOC(i) = SOC_actual;

    % -----------------------------------------------------
    % 8. REPORTE EN CONSOLA
    % -----------------------------------------------------

    fprintf('\nHora %02d:00 | %s\n', horas(i), ruta{i});
    fprintf('  Generacion: %5.1f kW | Demanda: %5.1f kW | Balance: %+6.1f kW\n', ...
            generacion_total(i), demanda(i), balance(i));
    fprintf('  Nuevo SOC: %6.2f %%\n', SOC(i));
    fprintf('  Escuela: %s | Bombeo: %s | Alumbrado: %s\n', ...
            estados{escuela(i)+1}, estados{bombeo(i)+1}, estados{alumbrado(i)+1});

end

% ---------------------------------------------------------
% 9. TABLA FINAL DE RESULTADOS
% ---------------------------------------------------------

fprintf('\n');
fprintf('============================================================\n');
fprintf('        RESUMEN DE LA SIMULACION DE LA MICRO-RED\n');
fprintf('============================================================\n');
fprintf('Hora   Gen.   Dem.   Balance   SOC(%%)   Escuela   Bombeo   Alumbrado\n');

for i = 1:24
    fprintf('%2d    %5.1f  %5.1f   %6.1f   %6.1f      %d         %d          %d\n', ...
        horas(i), generacion_total(i), demanda(i), ...
        balance(i), SOC(i), escuela(i), ...
        bombeo(i), alumbrado(i));
end

% ---------------------------------------------------------
% 10. GRAFICA DEL CONTROL ENERGETICO
% ---------------------------------------------------------

figure;

plot(horas, generacion_total, '-o', 'LineWidth', 1.5);
hold on;
plot(horas, demanda, '-s', 'LineWidth', 1.5);
plot(horas, SOC, '-^', 'LineWidth', 1.5);

% Umbrales de desconexion de cargas (40% y 20% de SOC).
plot([1 24], [40 40], '--k');
plot([1 24], [20 20], '--r');

grid on;
title('Control Energetico de la Micro-red Hibrida');
xlabel('Tiempo en horas');
ylabel('Potencia (kW) / Estado de carga (%)');
legend('Generacion Total', 'Demanda', 'SOC de la Bateria', ...
       'Umbral 40%', 'Umbral 20%', 'Location', 'best');

xlim([1 24]);
ylim([0 105]);
xticks(1:24);

hold off;
