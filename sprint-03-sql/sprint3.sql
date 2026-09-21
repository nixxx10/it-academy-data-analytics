#Nivell 1
#Exercici 1.1

CREATE TABLE IF NOT EXISTS credit_card(
id VARCHAR(20) PRIMARY KEY, 
iban VARCHAR(50), 
pan VARCHAR(23), 
pin VARCHAR(4), 
cvv INT, 
expiring_date VARCHAR(20)
); 

ALTER TABLE transaction
MODIFY credit_card_id VARCHAR(20);

ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_credit
FOREIGN KEY (credit_card_id)
REFERENCES credit_card(id);

SELECT COUNT(credit_card.id)
FROM credit_card;

SELECT COUNT(DISTINCT credit_card.id)
FROM credit_card;


#Exercice 1.2

SELECT credit_card.iban
FROM credit_card
WHERE credit_card.id = 'CcU-2938';

UPDATE credit_card
SET iban = 'TR323456312213576817699999' 
WHERE credit_card.id = 'CcU-2938';

#Ejercicio 1.3: 

SELECT id
FROM credit_card
WHERE id = 'CcU-9999';

SELECT id
FROM company
WHERE id = 'b-9999';

INSERT INTO company (id)
VALUES ('b-9999');

INSERT INTO credit_card (id)
VALUES ('CcU-9999');

INSERT INTO transaction (id, credit_card_id, company_id, user_id, lat, longitude, timestamp, amount, declined)
VALUES ('108B1D1D-5B23-A76C-55EF-C568E49A99DD', 'CcU-9999', 'b-9999', 9999, 829.999, -117.999, '2026-02-18 21:13:21', 111.11, 0);

SELECT *
FROM transaction
WHERE credit_card_id = 'CcU-9999';

-- Exercici 1.4:

ALTER TABLE credit_card
DROP COLUMN pan;

SELECT *
FROM credit_card;

-- -------------------------------------------------------------------
#Nivell 2
-- Exercici 2.1

SELECT *
FROM transaction
WHERE id =  '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

DELETE FROM transaction
WHERE id = "000447FE-B650-4DCF-85DE-C7ED0EE1CAAD";

#Exercici 2.2:

CREATE VIEW VistaMarketing AS
SELECT 
	c.company_name, 
    c.phone, 
    c.country, 
    ROUND(AVG(t.amount), 2) AS Mitjana_de_compres
FROM transaction t
INNER JOIN company c
	ON t.company_id = c.id
WHERE declined = 0
GROUP BY c.id, c.company_name, c.phone, c.country;

SELECT *
	FROM VistaMarketing
ORDER BY Mitjana_de_compres DESC;

-- Exercici 2.3 

SELECT* 
FROM VistaMarketing
WHERE country = 'Germany';

#Nivell 3
#Exercici 1

#Eliminamos el campo website de la tabla company
ALTER TABLE company
DROP COLUMN website;
#Eliminamos la VistaMarketing
DROP VIEW VistaMarketing;
#Creamos el campo fecha_actual en la tabla credit_card
ALTER TABLE credit_card
ADD COLUMN fecha_actual DATE;

#Creamos la tabla data_user
#(notese que el nombre de la tabla y del campo email son distintos al diagrama, posteriormente realizaremos los cambios necesarios):

CREATE TABLE IF NOT EXISTS user(
id INT PRIMARY KEY, 
name VARCHAR(100), 
surname VARCHAR(100), 
phone VARCHAR(100), 
email VARCHAR(150), 
birth_date VARCHAR(100),
country VARCHAR(150),
city VARCHAR(150),
postal_code VARCHAR(100),
address VARCHAR(255)
); 

#Modificamos el nombre del campo 'email' a 'personal_email'
ALTER TABLE user
RENAME COLUMN email TO personal_email;

#Modificamos el nombre de la tabla 'user' a 'data_user'
RENAME TABLE `user` TO data_user; 

ALTER TABLE data_user
MODIFY phone VARCHAR(150);

#Finalmente creamos la FK en transaction.user_id oara relacionar la tabla de hechos con la tabla de nueva creacion data_user: 
ALTER TABLE `transaction`
ADD CONSTRAINT fk_transaction_data
FOREIGN KEY (user_id)
REFERENCES data_user(id); 

#No me dejo crear el constraint debido a que aparecen registros en la tabla hija que no estan recogidos en la tabla madre (data_user).
#Con el siguiente comando compruebo cual de los valores son los que faltan por registrar en la tabla madre. 
SELECT t.user_id, COUNT(*) AS n
FROM transaction t
LEFT JOIN data_user u ON u.id = t.user_id
WHERE t.user_id IS NOT NULL
  AND u.id IS NULL
GROUP BY t.user_id
ORDER BY n DESC;

#Inserto el valor faltante en data_user.id 
INSERT INTO data_user (id)
VALUES (9999);

#Y ahora ya me permite crear el constrait y la FK en la tabla transaction: 
ALTER TABLE `transaction`
ADD CONSTRAINT fk_transaction_data
FOREIGN KEY (user_id)
REFERENCES data_user(id); 

#Exercici 2:
#ID de la transacció, Nom de l'usuari/ària, Cognom de l'usuari/ària, IBAN de la targeta de crèdit usada, 
#Nom de la companyia de la transacció realitzada , Assegureu-vos d'incloure informació rellevant de les taules que coneixereu
#i utilitzeu àlies per canviar de nom columnes segons calgui.
#Mostra els resultats de la vista, ordena els resultats de forma descendent en funció de la variable ID de transacció.

CREATE VIEW InformeTecnico AS
SELECT 
	t.id AS id_transaction, 
    du.name AS nombre_cliente, 
    du.surname AS apellido_cliente, 
    cc.iban, 
    c.company_name, 
    ROUND(SUM(t.amount), 2) AS total_amount_per_user, 
    TT.total_income_per_company, 
    TT.average_buy_per_client
FROM transaction t
INNER JOIN data_user du ON t.user_id = du.id
INNER JOIN credit_card cc ON t.credit_card_id = cc.id
INNER JOIN company c ON t.company_id = c.id
INNER JOIN (
	SELECT tr.company_id, ROUND(SUM(tr.amount), 2) AS total_income_per_company, ROUND(AVG(tr.amount), 2) AS average_buy_per_client
	FROM transaction tr
	GROUP BY tr.company_id) TT ON t.company_id = TT.company_id 
GROUP BY t.id, du.name, du.surname, cc.iban, c.company_name
ORDER BY t.id DESC;

SELECT*
FROM InformeTecnico;


