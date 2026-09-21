USE sprint4;

-- N1. Exercici 1. Crea la BBDD amb els CSV proporcionats. 

SHOW VARIABLES LIKE 'secure_file_priv'; #C:\ProgramData\MySQL\MySQL Server 8.0\Uploads 
# carpeta segura para importar CSVs to WB

-- ------------------------------------------------------------------------------   
#Primer crearem les taules a MySQL, a continuacio li introduim les dades dels CSV i finalment creem les constraints necessaries per 
-- crear les FK i enllassar les taules.

CREATE TABLE IF NOT EXISTS transactions (
	id VARCHAR(100) PRIMARY KEY,
	card_id VARCHAR(100),
	company_id VARCHAR(100),
	timestamp timestamp,
	amount DECIMAL(10, 2),
	declined TINYINT(1),
    products_ids TEXT,
	user_id VARCHAR(100),
	lat FLOAT,
	longitude FLOAT    
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/transactions.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

SELECT*
FROM transactions;   #Comprovem que la taula s'hagi creat correctament. 

ALTER TABLE transactions  #Aqui debo modificar el tipo de variable para que coincida con data_user.id y poder enlazar las tablas (FK).
MODIFY user_id INT;

-- -------------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS companies (
	id VARCHAR(100) PRIMARY KEY,
	company_name VARCHAR(100),
	phone VARCHAR(100),
	email VARCHAR(100),
	country VARCHAR(100),
	website VARCHAR(100)	
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/companies.csv'
INTO TABLE companies
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

SELECT*
FROM companies;   

-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS credit_cards (
	id VARCHAR(100) PRIMARY KEY,
	user_id VARCHAR(100),
	iban VARCHAR(100),
	pan VARCHAR(100),
	pin VARCHAR(100),
	cvv VARCHAR(100),
	track1 VARCHAR(100),
	track2 VARCHAR(100), 
    expiring_date VARCHAR(100)
    );


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/credit_cards.csv'
INTO TABLE credit_cards
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

SELECT* 
FROM credit_cards;

-- ---------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS data_users (
	id INT PRIMARY KEY,
	name VARCHAR(100),
	surname VARCHAR(100),
	phone VARCHAR(100),
	email VARCHAR(100),
	birth_date VARCHAR(100),
	country VARCHAR(100),
	city VARCHAR(100), 
    postal_code VARCHAR(100),
    address VARCHAR(300)
    );
    
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/data_users.csv'
INTO TABLE data_users
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '\\'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

SELECT* 
FROM data_users;

-- Creamos las FK para enlazar las tablas ------------------------------------------------------------------------------

ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_companies
FOREIGN KEY (company_id)
REFERENCES companies(id);

ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_card
FOREIGN KEY (card_id)
REFERENCES credit_cards(id);

ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_user
FOREIGN KEY (user_id)
REFERENCES data_users(id);

-- N1. Exercici 2: Subconsulta que mostri tots els usuaris amb més de 80 transaccions. Utilitza almenys 2 taules.


SELECT *
FROM data_users du 
INNER JOIN (
	SELECT du.id, COUNT(t.id) as suma_transaccions_usuari
	FROM transactions t 
	INNER JOIN data_users du
	ON t.user_id = du.id
	WHERE t.declined = 0 #Interpretamos que no se contabilizan las transacciones declinadas.
	GROUP BY du.id
	HAVING suma_transaccions_usuari > 80
    ) TT 
ON du.id = TT.id;

-- N1. Exercici 3: Mitjana d'amount per IBAN de les targetes de crèdit a la companyia Donec Ltd. Utilitza almenys 2 taules.


SELECT cc.iban, ROUND(AVG(t.amount), 2) AS 'avg_amount_x_iban'
FROM transactions t
INNER JOIN credit_cards cc ON t.card_id = cc.id
INNER JOIN companies c ON t.company_id = c.id
WHERE c.company_name = 'Donec Ltd'
GROUP BY cc.iban;

-- N2. Exercici 1: Nova taula que reflecteixi l'estat de les targetes de crèdit basat en si les tres últimes transaccions
-- han estat declinades o no:

CREATE TABLE card_status AS
SELECT
  card_id,
  CASE
    WHEN MIN(declined) = 1 THEN 'inactiva'
    ELSE 'activa'
  END AS status
FROM (
	SELECT t.card_id, t.declined, t.timestamp, ROW_NUMBER() OVER (
	PARTITION BY t.card_id ORDER BY timestamp DESC) AS rn FROM transactions t) TT
WHERE rn <= 3
GROUP BY card_id;

SELECT *
FROM card_status;

-- Quantes targetes estan actives?

SELECT COUNT(cs.card_id) AS targetes_actives
FROM card_status cs
WHERE status = 'activa'
GROUP BY cs.status;

-- N2 Exercici 2: Nova taula amb la qual puguem unir les dades del nou arxiu products.csv amb la base de dades creada, 
-- tenint en compte que des de transaction tens product_ids. 

CREATE TABLE IF NOT EXISTS products (
	id INT PRIMARY KEY,
	product_name VARCHAR(100),
	price DECIMAL(10, 2),
	colour VARCHAR(100),
	weight DECIMAL(10, 2),
	warehouse_id VARCHAR(100)
    );
    
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products_clean.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(id, product_name, price, colour, weight, warehouse_id);

SELECT*
FROM products;

-- Cambiamos el formato TEXT a JSON del campo product_ids de la tabla transactions: -------------------------------------

ALTER TABLE transactions #Creamos nueva columna JSON en transactions.alter
ADD COLUMN product_ids_json JSON; 

SET SESSION sql_safe_updates = 0;

UPDATE transactions
SET product_ids_json =
  CAST(CONCAT('[', REPLACE(products_ids, ' ', ''), ']') AS JSON);

SET SESSION sql_safe_updates = 1;

ALTER TABLE transactions #Eliminamos la antigua columna texto.
DROP COLUMN products_ids;

ALTER TABLE transactions #Renombramos la nueva columna = que la antigua. Solo le cambiamos el formato de TEXT a JSON.
CHANGE product_ids_json product_ids JSON;

CREATE TABLE transactions_products ( #Creamos la tabla intermedia transactions_products
  transaction_id VARCHAR(100) NOT NULL,
  product_id INT NOT NULL,
  PRIMARY KEY (transaction_id, product_id)
);

INSERT INTO transactions_products (transaction_id, product_id) #Poblamos la tabla intermedia transactions_products desde la columna JSON.
SELECT 
  t.id,
  j.product_id
FROM transactions t
JOIN JSON_TABLE(
  t.product_ids,
  '$[*]' COLUMNS (
    product_id INT PATH '$'
  )
) AS j;

#Creamos las CONSTRAINTS - las FK:

ALTER TABLE transactions_products
ADD CONSTRAINT fk_tp_transaction
FOREIGN KEY (transaction_id)
REFERENCES transactions(id)
ON DELETE CASCADE
ON UPDATE CASCADE;

ALTER TABLE transactions_products
ADD CONSTRAINT fk_tp_product
FOREIGN KEY (product_id)
REFERENCES products(id)
ON DELETE CASCADE
ON UPDATE CASCADE;

-- Nombre de vegades que s'ha venut cada producte?

SELECT tp.product_id, COUNT(tp.transaction_id) AS no_vendes
FROM transactions_products tp
INNER JOIN transactions t ON tp.transaction_id = t.id
WHERE t.declined = 0
GROUP BY tp.product_id
ORDER BY no_vendes DESC;
