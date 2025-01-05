/* 
This SQL script is the source for multiple dashboards, including:
1. Cash Activity Dashboard: Highlights cash trends and payer contributions.
2. Performance Insights Dashboard: Analyzes weekly performance and service location metrics.

Both dashboards are built on the data retrieved by this query.
*/


/* 
The following query is used to report cash collections for [Hospital]. 
Descriptions of functions or columns are provided in the subsequent lines for clarity.
*/




-- Uncomment the following line to use the `livendb` database:
-- USE livendb;

/* 
The `livendb` database contains the data required for this query. 
It is also the primary source of information relevant to the PFS department.
*/


SELECT
    -- Uncomment the following line to hash the AccountNumber using SHA2_512:
    -- HASHBYTES('SHA2_512', livendb.dbo.BarVisits.AccountNumber) AS 'HashedAccountNumber',
    livendb.dbo.BarVisits.AccountNumber AS 'AccountNumber',
    /* 
    The 'AccountNumber' is a unique identifier assigned to each patient visit, useful for tracking visit volume. 
    Note: For accounts categorized as 'hemo,' billing is processed monthly, meaning multiple visits within a 
    month are grouped under a single account number.
    */



CASE
    WHEN livendb.dbo.BarVisits.InpatientOrOutpatient = 'I' THEN 'Inpatient'
    ELSE 'Outpatient'
END AS [Inpatient Or Outpatient],
/* 
This field determines the patient type, classified as either 'Inpatient' or 'Outpatient.'
*/

livendb.dbo.BarVisitFinancialData.AccountType,
/* 
The 'AccountType' field identifies the department or line of business (LOB) that served the patient. 
The results correspond to the patient type, either 'Inpatient' or 'Outpatient.'
*/


CASE
    WHEN livendb.dbo.BarVisits.InpatientOrOutpatient = 'I' 
        THEN livendb.dbo.AdmVisits.LocationID
    WHEN livendb.dbo.BarVisitFinancialData.AccountType = 'O ER' 
        AND livefdb.dbo.EdmAcct_Main.EdLocation_EdmLocID = 'PSYCH' 
        THEN 'PSYCH ED'
    ELSE livendb.dbo.BarVisits.OutpatientLocationID
END AS 'Service/Location',
/* 
[Service/Location] will populate results based on the patient type. 
- Inpatients: Assigned to a specific location within the hospital after being admitted.
- Outpatients: Assigned to clinics or outpatient services locations.
*/

livendb.dbo.BarVisitFinancialData.BarStatus,
/* 
[BarStatus] indicates the status of the claim or visit:
- 'FB': The claim has been fully billed.
- 'BD': The claim has been submitted to collections.
- 'UB': The visit is currently unbilled.
*/

livendb.dbo.BarVisits.PrimaryInsuranceID,
/* 
[PrimaryInsuranceID] displays the primary insurance to be billed. 
While it is tied to financial queries or tables, it can also be considered part of demographic information based on its 
location. Additionally, it is useful for tracking patient volume.
*/



CASE
    WHEN livendb.dbo.BarVisits.AdmitDateTime IS NULL 
        THEN CONVERT(varchar(10), livendb.dbo.BarVisits.ServiceDateTime, 101)
    ELSE CONVERT(varchar(10), livendb.dbo.BarVisits.AdmitDateTime, 101)
END AS 'Date of Admission/DOS',

CASE
    WHEN livendb.dbo.BarVisits.DischargeDateTime IS NULL 
        THEN CONVERT(varchar(10), livendb.dbo.BarVisits.ServiceDateTime, 101)
    ELSE CONVERT(varchar(10), livendb.dbo.BarVisits.DischargeDateTime, 101)
END AS 'Date of Discharge/DOS',
/* 
[Date of Admission/DOS] and [Date of Discharge/DOS]:
- These fields determine the relevant dates for patient visits.
- [ServiceDateTime]: Applies to outpatient visits.
- [AdmitDateTime] and [DischargeDateTime]: Refer to the admission and discharge dates for inpatient visits.
*/

CASE 
    WHEN livendb.dbo.BarBchs.JournalID IN ('WINDOW2', 'WINDOW37', 'WINDOW1', 'WINDOW25', 'WINDOW4', 'WINDOW42', 'WINDOW41', 'WINDOW3') THEN 'SelfPay'
    WHEN livendb.dbo.BarBchTxns.InsuranceID = 'SP' THEN 'SelfPay'
    WHEN livendb.dbo.BarBchTxnItems.ProcedureID IN (
        'CLINUCA', 'PSPCHECK', 'WCUCA', 'CLINUVI', 'PSPMO', 'WCUCH', 'PSPVISA', 'CLINUCH', 
        'REHUCA', 'RADUCA', 'PSPBD', 'RADUMA', 'MHUCA', 'WCUVI', 'REHUVI', 'CLINUCC', 
        'PSPMASTER', 'PSPDISC', 'PSPAMEX', 'ERUCH', 'REHUCH', 'PSPCASH', 'MHUCH', 'ERUCA', 
        'CLINUMA', 'ERUMA', 'ERUMO'
    ) THEN 'SelfPay'
    /* 
    Self-pay is not included as an insurance type and appears on the insurance screen without a numerical sequence. 
    This can result in null values in the InsuranceOrder field for RCP transactions. The variables above are used 
    to assign a non-numerical sequence to rectify this issue.
    */
    WHEN livendb.dbo.BarInsuranceOrder.InsuranceOrderID = '1' THEN 'Primary'
    WHEN livendb.dbo.BarInsuranceOrder.InsuranceOrderID = '2' THEN 'Secondary'
    WHEN livendb.dbo.BarInsuranceOrder.InsuranceOrderID = '3' THEN 'Tertiary'
    WHEN livendb.dbo.BarInsuranceOrder.InsuranceOrderID = '4' THEN 'Quaternary'
    WHEN CONCAT('P', '', livendb.dbo.BarVisits.PrimaryInsuranceID) = livendb.dbo.BarBchTxnItems.ProcedureID THEN 'Primary'
    /* 
    The CONCAT function creates an identifier to help spot other primary payments.
    */
    ELSE livendb.dbo.BarInsuranceOrder.InsuranceOrderID
END AS 'InsuranceOrder',
/* 
[InsuranceOrder]:
- Patients may have multiple insurances organized in a hierarchy from 1 to 4/5.
- The field categorizes insurance as 'Primary,' 'Secondary,' 'Tertiary,' etc.
*/





CASE 
    WHEN livendb.dbo.BarBchs.JournalID IN ('WINDOW2', 'WINDOW37', 'WINDOW1', 'WINDOW25', 'WINDOW4', 'WINDOW42', 'WINDOW41', 'WINDOW3') THEN 'SP'
    WHEN livendb.dbo.BarBchTxnItems.ProcedureID IN (
        'CLINUCA', 'PSPCHECK', 'WCUCA', 'CLINUVI', 'PSPMO', 'WCUCH', 'PSPVISA', 'CLINUCH', 'REHUCA', 
        'RADUCA', 'PSPBD', 'RADUMA', 'MHUCA', 'WCUVI', 'REHUVI', 'CLINUCC', 'PSPMASTER', 'PSPDISC', 
        'PSPAMEX', 'ERUCH', 'REHUCH', 'PSPCASH', 'MHUCH', 'ERUCA', 'CLINUMA', 'ERUMA', 'ERUMO', 'RADUVI', 'ERUVI'
    ) THEN 'SP'
    /* 
    This part of the function categorizes specific transactions as 'Self-Pay' (SP), 
    similar to the logic referenced earlier.
    */
    WHEN livendb.dbo.DMisInsurance.DefaultFinancialClassID = 'WC' THEN 'NF/WC'
    WHEN livendb.dbo.DMisInsurance.DefaultFinancialClassID = 'NF' THEN 'NF/WC'
    WHEN livendb.dbo.DMisInsurance.DefaultFinancialClassID = 'COMM APC' THEN 'COMM'
    WHEN livendb.dbo.DMisInsurance.DefaultFinancialClassID = 'HMO APC' THEN 'HMO'
    WHEN livendb.dbo.DMisInsurance.DefaultFinancialClassID = 'TRICAREAPC' THEN 'TRICARE'
    WHEN livendb.dbo.BarInsuranceOrder.InsuranceOrderID IS NULL 
         AND livendb.dbo.BarBchTxns.InsuranceID IS NULL 
         AND livendb.dbo.DMisInsurance.DefaultFinancialClassID IS NULL THEN 'OTHER'
    ELSE livendb.dbo.DMisInsurance.DefaultFinancialClassID
END AS 'Paying Financial Class',
/* 
[Paying Financial Class]:
- Represents grouped financial classifications based on insurance ID.
- Provides a broader categorization of insurance payments when tied to RCPs.
*/

CASE
    WHEN livendb.dbo.BarBchs.JournalID IN ('WINDOW2', 'WINDOW37', 'WINDOW1', 'WINDOW25', 'WINDOW4', 'WINDOW42', 'WINDOW41', 'WINDOW3') THEN 'SP'
    WHEN livendb.dbo.BarBchTxnItems.ProcedureID IN (
        'CLINUCA', 'PSPCHECK', 'WCUCA', 'CLINUVI', 'PSPMO', 'WCUCH', 'PSPVISA', 'CLINUCH', 'REHUCA', 
        'RADUCA', 'PSPBD', 'RADUMA', 'MHUCA', 'WCUVI', 'REHUVI', 'CLINUCC', 'PSPMASTER', 'PSPDISC', 
        'PSPAMEX', 'ERUCH', 'REHUCH', 'PSPCASH', 'MHUCH', 'ERUCA', 'CLINUMA', 'ERUMA', 'ERUMO', 'RADUVI', 'ERUVI'
    ) THEN 'SP'
    ELSE livendb.dbo.BarBchTxns.InsuranceID
END AS 'Paying Insurance ID',
/* 
[Paying Insurance ID]:
- Identifies the insurance responsible for payment.
- Handles special cases like 'Self-Pay' transactions.
*/

livendb.dbo.BarBchs.JournalID,
/* [JournalID] categorizes transactions and is used to identify self-pay transactions. */

SUM(livendb.dbo.BarBchTxnItems.Amount) AS Total,
/





FROM livendb.dbo.BarVisits  
LEFT JOIN livendb.dbo.BarVisitFinancialData ON livendb.dbo.BarVisits.VisitID = livendb.dbo.BarVisitFinancialData.VisitID
LEFT JOIN livendb.dbo.AdmVisits ON livendb.dbo.BarVisitFinancialData.VisitID = livendb.dbo.AdmVisits.VisitID
LEFT JOIN livendb.dbo.BarBchTxns ON livendb.dbo.BarVisits.BillingID = livendb.dbo.BarBchTxns.BillingID
LEFT JOIN livendb.dbo.BarBchTxnItems ON livendb.dbo.BarBchTxns.TxnNumberID = livendb.dbo.BarBchTxnItems.TxnNumberID 
AND livendb.dbo.BarBchTxns.BatchID = livendb.dbo.BarBchTxnItems.BatchID
LEFT JOIN livendb.dbo.BarBchs ON livendb.dbo.BarBchTxns.BatchID = livendb.dbo.BarBchs.BatchID
LEFT JOIN livendb.dbo.BarInsuranceOrder ON livendb.dbo.BarBchTxns.BillingID = livendb.dbo.BarInsuranceOrder.BillingID
AND livendb.dbo.BarInsuranceOrder.InsuranceID  = livendb.dbo.BarBchTxns.InsuranceID
LEFT JOIN livendb.dbo.DMisInsurance ON livendb.dbo.BarBchTxns.SourceID = livendb.dbo.DMisInsurance.SourceID
AND livendb.dbo.BarBchTxns.InsuranceID = livendb.dbo.DMisInsurance.InsuranceID
LEFT JOIN livefdb.dbo.EdmAcct_Main ON livendb.dbo.BarVisits.VisitID = livefdb.dbo.EdmAcct_Main.VisitID
LEFT JOIN livendb.dbo.DBarProcedures ON livendb.dbo.BarBchTxnItems.SourceID = livendb.dbo.DBarProcedures.SourceID
AND livendb.dbo.BarBchTxnItems.ProcedureID = livendb.dbo.DBarProcedures.ProcedureID
--line (livefdb.dbo.EdmAcct_Main ON livendb.dbo.BarVisits.VisitID = livefdb.dbo.EdmAcct_Main.VisitID) was added to identify PTs that are account O ER but are here for psych




WHERE 
    (livendb.dbo.BarBchs.Status = 'POSTED'
    AND livendb.dbo.BarBchs.DateTime BETWEEN DATEADD(year, DATEDIFF(year, 0, GETDATE())-3, 0) AND CONVERT(date, GETDATE())
    AND livendb.dbo.BarBchTxnItems.Type = 'RCP')
/* 
Explanation of the WHERE clause:
- [Status = 'POSTED']: Filters transactions where the batch status is marked as 'POSTED,' indicating that the payments have been finalized.
- [DateTime BETWEEN]: Restricts results to transactions posted within the last three years, starting from the beginning of the year three years ago up to the current date.
  - DATEADD and DATEDIFF calculate the start date three years ago.
  - CONVERT(date, GETDATE()) ensures the end date is today's date without the time component.
- [Type = 'RCP']: Includes only transactions of type 'RCP' (likely referring to a specific payment or transaction type, such as receipts).
*/



AND livendb.dbo.BarBchTxnItems.Amount != '0'


GROUP BY
livendb.dbo.BarVisits.AccountNumber, 
AccountType,
IIF(livendb.dbo.BarVisits.InpatientOrOutpatient = 'I','Inpatient','Outpatient'),
livefdb.dbo.EdmAcct_Main.EdLocation_EdmLocID,
livendb.dbo.BarVisits.ServiceDateTime,
livendb.dbo.BarVisits.AdmitDateTime,
livendb.dbo.BarVisits.DischargeDateTime,
livendb.dbo.BarVisits.InpatientOrOutpatient,
livendb.dbo.AdmVisits.LocationID,
livendb.dbo.BarVisits.OutpatientLocationID,
livendb.dbo.BarVisitFinancialData.BarStatus,
livendb.dbo.BarVisits.PrimaryInsuranceID,
livendb.dbo.BarInsuranceOrder.InsuranceOrderID,
livendb.dbo.BarInsuranceOrder.InsuranceID,
livendb.dbo.BarBchTxns.InsuranceID,
livendb.dbo.BarBchs.JournalID,
livendb.dbo.DMisInsurance.DefaultFinancialClassID,
livendb.dbo.BarBchTxnItems.ProcedureID,
livendb.dbo.BarBchs.DateTime,
livendb.dbo.DBarProcedures.BillDescription

