/*--------------------------------
Melbourne Datathon 2015

this code loads file that was modified by
the R code into Microsoft SQL Server and 
creates some features.


---------------------------------*/

CREATE DATABASE DATATHON

GO

USE DATATHON

GO

CREATE TABLE Datathon_WC_Data_Games_SEMI_Finals_Final
(
	BET_ID	float
,	BET_TRANS_ID	float
,	MATCH_BET_ID	float
,	ACCOUNT_ID	int
,	COUNTRY_OF_RESIDENCE_NAME	varchar(23)
,	PARENT_EVENT_ID	int
,	EVENT_ID	int
,	MATCH	varchar(26)
,	EVENT_NAME	varchar(10)
,	EVENT_DT	varchar(21)  -- DATETIME could be a date
,	OFF_DT	varchar(21)  -- DATETIME could be a date
,	BID_TYP	varchar(1)
,	STATUS_ID	varchar(1)
,	PLACED_DATE	varchar(22)  -- DATETIME could be a date
,	TAKEN_DATE	varchar(22)  -- DATETIME could be a date
,	SETTLED_DATE	varchar(22)  -- DATETIME could be a date
,	CANCELLED_DATE	varchar(22)  -- DATETIME could be a date
,	SELECTION_NAME	varchar(12)
,	PERSISTENCE_TYPE	varchar(2)
,	BET_PRICE	float
,	PRICE_TAKEN	float
,	INPLAY_BET	varchar(1)
,	BET_SIZE	float
,	PROFIT_LOSS	float
,	EVENT_DT1	DATETIME 
,	OFF_DT1	DATETIME 
,	PLACED_DATE1	DATETIME 
,	TAKEN_DATE1	DATETIME 
,	SETTLED_DATE1 DATETIME 
,	CANCELLED_DATE1 DATETIME 
)

GO

BULK INSERT Datathon_WC_Data_Games_SEMI_Finals_Final
FROM 'H:\DataScienceMelbourne\datathon_data\Datathon_WC_Data_Games_SEMI_Finals_Final.txt'
WITH
(
MAXERRORS = 0,
FIRSTROW = 2,
FIELDTERMINATOR = '\t',
ROWTERMINATOR = '\n'
)

GO


------------------------
--correct the profit
------------------------
ALTER TABLE Datathon_WC_Data_Games_SEMI_Finals_Final ADD PROFIT_LOSS1 FLOAT

GO

UPDATE Datathon_WC_Data_Games_SEMI_Finals_Final 
SET PROFIT_LOSS1 =
		CASE
			WHEN PROFIT_LOSS > 0 AND BID_TYP = 'B' THEN  (PRICE_TAKEN-1.0) * BET_SIZE
			WHEN PROFIT_LOSS > 0 AND BID_TYP = 'L' THEN  BET_SIZE
			WHEN PROFIT_LOSS < 0 AND BID_TYP = 'L' THEN (PRICE_TAKEN-1.0) * -1.0 * BET_SIZE
			WHEN PROFIT_LOSS < 0 AND BID_TYP = 'B' THEN -1.0 * BET_SIZE
			ELSE PROFIT_LOSS
		END

GO


--------------------------------
-- create some features
-------------------------------
drop table #temp

go

select 
	Account_ID
	,EVENT_ID
	,COUNT(*) AS TRANSACTION_COUNT
	,STATUS_ID
	,INPLAY_BET
	,AVG(BET_SIZE) AS AVG_BET_SIZE
	,MAX(BET_SIZE) AS MAX_BET_SIZE
	,MIN(BET_SIZE) AS MIN_BET_SIZE
	,STDEV(BET_SIZE) AS STDEV_BET_SIZE
	--,SUM(PROFIT_LOSS1) AS PROFIT_LOSS1 -this is essentially what we need to predict
INTO 
	#TEMP
FROM
	Datathon_WC_Data_Games_SEMI_Finals_Final
GROUP BY 
	Account_ID
	,EVENT_ID
	,BID_TYP
	,STATUS_ID
	,INPLAY_BET
GO

UPDATE #TEMP
SET STDEV_BET_SIZE = 0 WHERE STDEV_BET_SIZE IS NULL

GO

/*------------------------------------------------
  This is the feature file you are provided with

  The idea is that you might create these features
  for the games you have and then try to model
  profit, then predict profit on the finals
  dataset
-------------------------------------------------*/

SELECT * 
FROM #TEMP
ORDER BY 
	Account_ID
	,EVENT_ID
	,STATUS_ID
	,INPLAY_BET






/*-------------------------------------
This is the list of 
Account_IDs you need
to provide predictions for

Note we exclude IDs where the 
BET_SIZE over the 3 finals games
is < $200

We are trying to predict if an account
made a profit or not
---------------------------------------*/

SELECT 
	Account_ID
	,SUM(PROFIT_LOSS1) AS PROFIT_LOSS_VALUE
	,PROFIT_BINARY = (CASE 
		WHEN SUM(PROFIT_LOSS1) > 0 THEN 1
		ELSE 0
	 END)
FROM 
	Datathon_WC_Data_Games_SEMI_Finals_Final
WHERE
	STATUS_ID = 'S'
GROUP BY
	Account_ID
HAVING SUM(BET_SIZE) > 200
ORDER BY
 PROFIT_LOSS_VALUE


 --sample prediction file based on bet_size
 SELECT 
	Account_ID
	,SUM(BET_SIZE) AS Prediction
FROM 
	Datathon_WC_Data_Games_SEMI_Finals_Final
WHERE
	STATUS_ID = 'S'
GROUP BY 
	Account_ID
HAVING 
	SUM(BET_SIZE) > 200
ORDER BY
	Account_ID

--or

SELECT 
	Account_ID
	,SUM(AVG_BET_SIZE * TRANSACTION_COUNT) AS Prediction
FROM 
	#TEMP
 WHERE 
	STATUS_ID = 'S'
GROUP BY
	Account_ID
HAVING 
	SUM(AVG_BET_SIZE * TRANSACTION_COUNT) > 200
ORDER BY
	Account_ID















