USE transactions;

#NIVELL 1: 
#2.1. Llistat dels països que estan generant vendes:

SELECT DISTINCT c.country
FROM transaction t
INNER JOIN company c ON t.company_id = c.id
WHERE t.declined = 0;

#2.2. Desde quants països es realitzen les vendes?


SELECT COUNT(DISTINCT c.country) AS 'Paisos'
FROM transaction t
INNER JOIN company c ON t.company_id = c.id
WHERE t.declined = 0;


#2.3. Identifica la companyia amb la mitjana més gran de vendes.
SELECT c.id, c.company_name, ROUND(AVG(t.amount), 2) AS 'Mitjana Vendes'
FROM company c
INNER JOIN transaction t ON c.id = t.company_id
WHERE t.declined = 0
GROUP BY c.company_name, c.id
ORDER BY AVG(t.amount) DESC
LIMIT 1;

#3.1. Mostra totes les transaccions realitzades per empreses d'Alemanya.
SELECT *
FROM transaction t
WHERE company_id IN (
    SELECT c.id
    FROM company c
    WHERE c.country = 'Germany'
)
AND t.declined = 0;


#3.2. Llista les empreses que han realitzat transaccions per un amount superior a la mitjana de totes les transaccions. 


SELECT c.company_name,
       c.id
FROM company c
WHERE EXISTS (
    SELECT DISTINCT tra.company_id
    FROM transaction tra
    WHERE tra.amount > (
        SELECT AVG(tr.amount)
        FROM transaction tr
    ));

#3.3. Eliminaran del sistema les empreses que no tenen transaccions registrades, entrega el llistat d'aquestes empreses.
#Encontrar empresas sin registros en transacciones. Si estan en transacciones significa que tienen registros por lo tanto tenemos q
#cuadrar las empresas que aparecen en company y que por tanto tienen un company.id y las que NO aparecen en transacciones y que por lo tanto
#NO aparecen en transactions.company_id. 

SELECT c.id, c.company_name
FROM company c
WHERE c.id NOT IN (
    SELECT t.company_id
    FROM transaction t
    WHERE t.company_id IS NOT NULL
);

#Nivell 2: 
#1. Identifica els cinc dies que es va generar la quantitat més gran d'ingressos a l'empresa per vendes. 
#Mostra la data de cada transacció juntament amb el total de les vendes.

SELECT DATE(t.timestamp) AS `data`, SUM(t.amount) AS total_sales
FROM transaction t
WHERE t.declined = 0
GROUP BY DATE(t.timestamp)
ORDER BY SUM(t.amount) DESC
LIMIT 5;



#2. Quina és la mitjana de vendes per país? Presenta els resultats ordenats de major a menor mitjà.


SELECT c.id, c.country, ROUND(AVG(t.amount), 2) AS 'Promedio Ventas'
FROM transaction t
INNER JOIN company c ON t.company_id = c.id
WHERE t.declined = 0
GROUP BY c.id, c.country
ORDER BY AVG(t.amount) DESC;




#3.A. En la teva empresa, es planteja un nou projecte per a llançar algunes campanyes publicitàries per a fer competència a la companyia "Non Institute". Per a això, et demanen la llista de totes les transaccions realitzades per empreses que estan situades en el mateix país que aquesta companyia.
# Mostra el llistat aplicant JOIN i subconsultes.
SELECT *
FROM transaction t
INNER JOIN company c
        ON t.company_id = c.id
WHERE c.country = (
          SELECT c.country
          FROM company c
          WHERE c.company_name = 'Non Institute'
      )
  AND c.company_name <> 'Non Institute';



#3.B. En la teva empresa, es planteja un nou projecte per a llançar algunes campanyes publicitàries per a fer competència a la companyia "Non Institute".
# Per a això, et demanen la llista de totes les transaccions realitzades per empreses que estan situades en el mateix país que aquesta companyia.
# Mostra el llistat aplicant nomes subconsultes.


SELECT t.id,
       t.company_id
FROM transaction t
WHERE t.company_id IN (
    SELECT c.id
    FROM company c
    WHERE c.country = (
        SELECT c.country
        FROM company c
        WHERE c.company_name = 'Non Institute')
      AND c.company_name <> 'Non Institute');


# Nivell 3:
#1. Presenta el nom, telèfon, país, data i amount, 
#d'aquelles empreses que van realitzar transaccions amb un valor comprès entre 350 i 400 euros
#i en alguna d'aquestes dates: 29 d'abril del 2015, 20 de juliol del 2018 i 13 de març del 2024. 
#Ordena els resultats de major a menor quantitat.

SELECT c.company_name, c.phone, c.country, DATE(t.timestamp) AS `data`, t.amount
FROM company c
INNER JOIN transaction t ON c.id = t.company_id
WHERE t.amount BETWEEN 350 AND 400
AND DATE(t.timestamp) IN ('2015-04-29', '2018-07-20', '2024-03-13')
ORDER BY t.amount DESC;


#2. Demanen la informació sobre la quantitat de transaccions que realitzen les empreses, 
#però vol un llistat de les empreses on especifiquis si tenen més de 400 transaccions o menys.


SELECT c.id, c.company_name, COUNT(t.id) AS 'Quantitat transaccions',
CASE
WHEN COUNT(t.id) > 400 THEN 'Mes de 400'
ELSE '400 o menys'
END AS 'Classificacio x transaccions'
FROM company c
INNER JOIN transaction t ON c.id = t.company_id
GROUP BY c.id, c.company_name;



