--general table creation and process

--TESTRESULT
CREATE TABLE TESTRESULT (
  TESTID INT 
  ,VEHICLEID INT 
  ,TESTDATE DATE
  ,TESTCLASSID CHAR(2)
  ,TESTTYPE CHAR(2)
  ,TESTRESULT CHAR(3)
  ,TESTMILEAGE INT 
  ,POSTCODEREGION CHAR(2)
  ,MAKE CHAR(30)
  ,MODEL CHAR(30)
  ,COLOUR CHAR(16)
  ,FUELTYPE CHAR(1)
  ,CYLCPCTY INT 
  ,FIRSTUSEDATE DATE
  ,PRIMARY KEY (TESTID)
  ,constraint test_id_nonzero check (TESTID > 0)
  ,constraint vehicle_id_nonzero check (VEHICLEID > 0)
  ,constraint testmileage_nonzero check (TESTMILEAGE > 0)
  ,constraint cyclecapacity_nonzero check (CYLCPCTY > 0)
  )
;

CREATE INDEX IDX1 ON  TESTRESULT(TESTDATE, TESTTYPE, TESTRESULT, TESTCLASSID)
;

--TESTITEM
CREATE TABLE TESTITEM (
	TESTID INT
	,RFRID SMALLINT
	,RFRTYPE CHAR(1)
	,LATLOCATIONID CHAR(1)
	,LONGLOCATIONID CHAR(1)
	,VERTLOCATIONID CHAR(1)
	,DMARK CHAR(1)
	,constraint test_id_nonzero1 check (TESTID > 0)
  ,constraint rfr_id_nonzero1 check (RFRID > 0)
	)
;

CREATE INDEX IDX2 ON  TESTITEM(TESTID)
;

CREATE INDEX IDX3 ON  TESTITEM(RFRID)
;

--TESTITEM_DETAIL
CREATE TABLE TESTITEM_DETAIL (
	RFRID SMALLINT
	,TESTCLASSID CHAR(2)
	,TSTITMID SMALLINT
	,MINORITEM CHAR(1)
	,RFRDESC CHAR(250)
	,RFRLOCMARKER CHAR(1)
	,RFRINSPMANDESC CHAR(500)
	,RFRADVISORYTEXT CHAR(250)
	,TSTITMSETSECID SMALLINT
	,PRIMARY KEY (RFRID, TESTCLASSID)
	,constraint rfr_id_nonzero check (RFRID > 0)
  ,constraint tstitmid_id_nonzero check (TSTITMID > 0)
  ,constraint tstitmsetsecid_id_nonzero check (TSTITMSETSECID > 0)
	)
;

CREATE INDEX IDX4 ON  TESTITEM_DETAIL(TSTITMID, TESTCLASSID)
;

CREATE INDEX IDX5 ON  TESTITEM_DETAIL(TSTITMSETSECID, TESTCLASSID)
;
--TESTITEM_GROUP
CREATE TABLE TESTITEM_GROUP (
	TSTITMID SMALLINT 
  ,TESTCLASSID CHAR(2)
	,PARENTID SMALLINT
	,TSTITMSETSECID SMALLINT
	,ITEMNAME CHAR(100)
	,PRIMARY KEY (TSTITMID, TESTCLASSID)
  ,constraint tstitmid_id_nonzero1 check (TSTITMID > 0)
  ,constraint parent_id_nonzero check (PARENTID > 0)
  ,constraint tstitmsetsecid_id_nonzero1 check (TSTITMSETSECID > 0)
  )
  ;
  
CREATE INDEX IDX6 ON TESTITEM_GROUP (PARENTID, TESTCLASSID);
CREATE INDEX IDX7 ON TESTITEM_GROUP(TSTITMSETSECID, TESTCLASSID);


---Initial, Completed Test Volumes by Class 2013 (As calculated in VOSA effectiveness report)
SELECT TESTCLASSID
	,TESTRESULT
	,COUNT(*) AS TEST_VOLUME
FROM TESTRESULT
WHERE TESTTYPE='N'
	AND TESTRESULT IN('P','F','PRS')
  --AND TESTDATE BETWEEN '2009-04-01' AND '2010-03-31'
  AND trunc(TESTDATE) BETWEEN '01-Jan-2013' AND '31-Mar-2013'
GROUP BY TESTCLASSID
	,TESTRESULT
;

---RfR Volumes and Distinct Test Failures 2008 for Class 7 Vehicles by Top Level Test Item Group (For vehicles as presented for initial test)
SELECT d.ITEMNAME
	,COUNT(*) AS RFR_VOLUME
	,COUNT(DISTINCT a.TESTID) AS TEST_VOLUME
FROM TESTRESULT a
	INNER JOIN TESTITEM b
		ON a.TESTID=b.TESTID
	INNER JOIN TESTITEM_DETAIL c
		ON b.RFRID=c.RFRID
		AND a.TESTCLASSID = c.TESTCLASSID
	INNER JOIN TESTITEM_GROUP d
		ON c.TSTITMSETSECID = d.TSTITMID
		AND c.TESTCLASSID = d.TESTCLASSID
WHERE a.TESTDATE BETWEEN '01-Jan-2008' AND '31-Dec-2013'
	AND a.TESTCLASSID = '7'
	AND a.TESTTYPE='N'
	AND a.TESTRESULT IN('F','PRS')
	AND b.RFRTYPE IN('F','P')
GROUP BY d.ITEMNAME
;

-----Basic Expansion of RfR Hierarchy for Class 5 Vehicles
SELECT a.RFRID
	,a.RFRDESC
	,b.ITEMNAME AS LEVEL1
	,c.ITEMNAME AS LEVEL2
	,d.ITEMNAME AS LEVEL3
	,e.ITEMNAME AS LEVEL4
	,f.ITEMNAME AS LEVEL5
FROM TESTITEM_DETAIL a
	INNER JOIN TESTITEM_GROUP b
		ON a.TSTITMID = b.TSTITMID
		AND a.TESTCLASSID = b.TESTCLASSID
	LEFT JOIN TESTITEM_GROUP c
		ON b.PARENTID = c.TSTITMID
		AND b.TESTCLASSID = c.TESTCLASSID
	LEFT JOIN TESTITEM_GROUP d
		ON c.PARENTID = d.TSTITMID
		AND c.TESTCLASSID = d.TESTCLASSID
	LEFT JOIN TESTITEM_GROUP e
		ON d.PARENTID = e.TSTITMID
		AND d.TESTCLASSID = e.TESTCLASSID
	LEFT JOIN TESTITEM_GROUP f
		ON e.PARENTID = f.TSTITMID
		AND e.TESTCLASSID = f.TESTCLASSID
WHERE a.TESTCLASSID = '5'
;

select count(testid) from testresult -- 37390457

select count(distinct testid) from testresult -- 37390457

select count(distinct vehicleid) from testresult -- 27823579


drop view failreasons ;

create view failreasons as
SELECT distinct g.testid, a.RFRID
  ,a.RFRDESC
  ,b.ITEMNAME AS LEVEL1
  ,c.ITEMNAME AS LEVEL2
  ,d.ITEMNAME AS LEVEL3
  ,e.ITEMNAME AS LEVEL4
  ,f.ITEMNAME AS LEVEL5  
FROM testresult g, testitem h, TESTITEM_DETAIL a
  INNER JOIN TESTITEM_GROUP b
    ON a.TSTITMID = b.TSTITMID
    AND a.TESTCLASSID = b.TESTCLASSID
  LEFT JOIN TESTITEM_GROUP c
    ON b.PARENTID = c.TSTITMID
    AND b.TESTCLASSID = c.TESTCLASSID
  LEFT JOIN TESTITEM_GROUP d
    ON c.PARENTID = d.TSTITMID
    AND c.TESTCLASSID = d.TESTCLASSID
  LEFT JOIN TESTITEM_GROUP e
    ON d.PARENTID = e.TSTITMID
    AND d.TESTCLASSID = e.TESTCLASSID
  LEFT JOIN TESTITEM_GROUP f
    ON e.PARENTID = f.TSTITMID
    AND e.TESTCLASSID = f.TESTCLASSID
    where g.testid = h.testid
and a.rfrid = h.rfrid


create table MOT2013 AS 
select /*+parallel*/ b.*,a.rfrid, a.rfrdesc, a.level1, a.level2, a.level3,a.level4,a.level5
from failreasons a, testresult b
where a.testid = b.testid
order by b.testid

DROP VIEW MOT2013VIEW;
--view is focused on make and model, so stuff like vehicleid, testclassid, testdate removed
create VIEW MOT2013VIEW AS 
select /*+parallel*/ b.testid, b.make, b.model, a.rfrid, a.rfrdesc, a.level1, a.level2, a.level3
from failreasons a, testresult b
where a.testid = b.testid
and make <> 'UNCLASSIFIED'
AND TESTRESULT = 'F'
AND TESTTYPE = 'N'
order by b.testid;

create table MOT2013 as select /*+parallel*/ * from mot2013view

select count(1) from MOT2013 -- 30264239

select /*+parallel*/ * from MOT2013 where level2 = 'Vehicle' and rownum < 6

select * from MOT2013 where level2 = 'Vehicle' limit 5

select * from MOT2013FAULTSUMMARY


create table MOT2013FAULTSUMMARY AS select /*+parallel*/ make, rfrdesc, level3, count(make) Number_of_Cars from MOT2013 group by make, rfrdesc, level3

create index idx11 on mot2013(make)

select * from MOT2013FAULTSUMMARY order by make, number_of_cars desc

select distinct make, level3 from loop_over_vehicles order by make

select count(1) from MOT2013FAULTSUMMARY

create table MOT2013FAULTSUMMARYSUMMED as
select make, level3, sum(number_of_cars) CATEGORYSUM from
MOT2013FAULTSUMMARY group by make,level3
order by make


SELECT CATEGORYSUM, MAKE FROM MOT2013FAULTSUMMARYSUMMED ORDER BY CATEGORYSUM DESC


select * from MOT2013FAULTSUMMARYSUMMED



select make,
       level3,
       categorysum
from
(
select distinct make,
       level3,
       categorysum,
       max(categorysum) over (partition by make) max_categorysum
from   MOT2013FAULTSUMMARYSUMMED
)
where categorysum = max_categorysum

SELECT categorysum
  FROM (SELECT categorysum,
               dense_rank() over (partition by make, order by categorysum desc) rnk               
          FROM MOT2013FAULTSUMMARYSUMMED)          
 WHERE rnk = 2
 and 
 
 SELECT categorysum
  FROM (SELECT categorysum,
               dense_rank() over (order by categorysum desc) rnk ,
                            
          FROM MOT2013FAULTSUMMARYSUMMED)          
 WHERE rnk = 2


select decode(categorysum, 

SELECT @rn :=  CASE WHEN @prev_grp <> groupa THEN 1 ELSE @rn+1 END AS rn,  
   @prev_grp :=groupa,
   person,age,groupa  
FROM   MOT2013FAULTSUMMARYSUMMED,(SELECT @rn := 0) r        
HAVING rn=1
ORDER  BY make,categorysum DESC,level3

declare 
int sum1 = 0;
int sum2 = 0;
cursor loop_over_vehicles is
select distinct make, level3 from MOT2013FAULTSUMMARY order by make
for vehicle_make in loop_over_vehicles
  begin
    loop
      select sum(Number_of_Cars) into sum1 from MOT2013FAULTSUMMARY
      where make = vehicle_make.make
      and level3 = vehicle_make.level3;
      
      update MOT2013FAULTSUMMARY 
      set faultgroupsum = sum1
      where vehicle_make.make
      and level3 = vehicle_make.level3;
      commit;
      
    end loop;
  end ;

--------------------------------------------------junk-------------------------------------------------
create table MOT2013FAULTSUMMARY1 as select * from MOT2013FAULTSUMMARY

declare 
int sum1 := 0;
int sum2 := 0;
cursor loop_over_vehicles is
select distinct make, level3 from MOT2013FAULTSUMMARY1 order by make

  begin
    for vehicle_make in loop_over_vehicles
    loop
      select sum(Number_of_Cars) into sum1 from MOT2013FAULTSUMMARY1
      where make = vehicle_make.make
      and level3 = vehicle_make.level3;
      
      update MOT2013FAULTSUMMARY1 
      set faultgroupsum = sum1
      where vehicle_make.make
      and level3 = vehicle_make.level3;
      commit;
      
    end loop;
  end ;
   


