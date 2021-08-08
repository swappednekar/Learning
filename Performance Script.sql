USE DukeAccount
GO
SET NOCOUNT ON
DECLARE @StepDetails TABLE(RowNo INT,Val VARCHAR(200))

IF(OBJECT_ID(N'tempdb..#ClaimTOT') IS NOT NULL)
BEGIN 
	DROP TABLE #ClaimTOT
END

CREATE TABLE #ClaimTOT
(ClmNo INT,
StepResultDetails VARCHAR(MAX),
rsPRMatch DECIMAL,
rsDupeCheck DECIMAL,
UpdateCLHRecord DECIMAL,
AddClaimLines DECIMAL,
FixDatesOfServices DECIMAL,
FixClaimAmounts DECIMAL,
AddClaimCodes DECIMAL,
AddIndicators DECIMAL,
ClientProductValidation DECIMAL,
AddClaimUBHeader DECIMAL,
AddClaimCLHOtherInfo DECIMAL,
DRTARequestScreening DECIMAL,
FinalizeSaveToDUKE DECIMAL,
PatientProviderMatch DECIMAL,
AddHasSuppressibleLinesFlag DECIMAL,
ChangeSubAccount DECIMAL,
TeaRules DECIMAL,
PricingRules DECIMAL,
PreCheck DECIMAL,
CallFred DECIMAL,
rsPricing DECIMAL,
PostCheck DECIMAL,
rsRace DECIMAL,
[MRAX.Realtime] DECIMAL
)
INSERT INTO #ClaimTOT(clmNo, StepResultDetails)
select ClmNo, StepResultDetails from ApplicationLogs..drteventlog where clmno in(

select DUKEClaimNumber from EDISystem..DirectConnectionSubmitTracking 
WHERE --MPClaimNumber LIKE '%_automation'
HtmlRequestReceivedDT >= '2021/05/11 10:41:27.945'
AND HtmlRequestReceivedDT <= '2021/05/11 11:11:59.500' and IsRealTime=1) and StepName='Total Time Elapsed'

DECLARE @clmNo INT, @StepResultDetails VARCHAR(MAX)
DECLARE curTot CURSOR
FOR select clmno, StepResultDetails from #ClaimTOT

OPEN curTot

FETCH NEXT FROM curTot INTO @clmNo, @StepResultDetails

WHILE(@@FETCH_STATUS=0)
BEGIN 
	DELETE @StepDetails
	INSERT INTO @StepDetails
	SELECT * from fnSplit('|',@StepResultDetails)
	
	DECLARE @ctr INT=1, @tot INT, @val VARCHAR(200);
	DECLARE @strUpdate NVARCHAR(MAX) = 'UPDATE #ClaimTot SET ###
									 WHERE ClmNo=' + CONVERT(VARCHAR,@clmNo)
	SELECT @tot = COUNT(1) FROM @StepDetails
	DECLARE @ColName VARCHAR(100), @pos INT, @Colval DECIMAL, @COLUpdate VARCHAR(1000)=''
	WHILE(@ctr<= @tot)
	BEGIN 
		SELECT @val = val from @StepDetails WHERE RowNo = @ctr
		IF( @val <> '' )
		BEGIN
			SET @val = REPLACE(@val,'ApplyInboundPlugins-','')
			SELECT @pos = CHARINDEX('-',@val)
			SELECT @ColName = SUBSTRING(@val, 0, @pos)
			--print @val
			--print @Pos 
			SELECT @Colval = SUBSTRING(@val, @Pos + 1,LEN(@val)) 
			SET @Colval = @Colval / 1000
			if(CHARINDEX(@ColName,@COLUpdate) = 0)
				SET @COLUpdate = @COLUpdate + '[' + @ColName + '] = ' + CONVERT(VARCHAR,@Colval) + ', '
		END
		
		SET @ctr = @ctr+1
	END
	SET @COLUpdate = SUBSTRING(@COLUpdate,0,LEN(@COLUpdate)	)
	SET @strUpdate = REPLACE(@strUpdate,'###', @COLUpdate)
	
	EXECUTE sp_executeSQL @strUpdate
	FETCH NEXT FROM curTot INTO @clmNo, @StepResultDetails
END	
CLOSE curTot
DEALLOCATE curTot

SELECT AVG(rsPRMatch) as rsPRmatch,
AVG(ChangeSubAccount) as ChangeSubAccount,
AVG(PatientProviderMatch) as PatientProviderMatch,
AVG(AddHasSuppressibleLinesFlag) as AddHasSuppressibleLinesFlag,
AVG(AddClaimUBHeader) as AddClaimUBHeader,
AVG(rsDupeCheck) as rsDupeCheck,
AVG(UpdateCLHRecord) as UpdateCLHRecord,
AVG(AddClaimLines) as AddClaimLines,
AVG(FixDatesOfServices) as FixDatesOfServices,
AVG(AddIndicators) as AddIndicators,
AVG(AddClaimCLHOtherInfo) as AddClaimCLHOtherInfo,
AVG(DRTARequestScreening) as DRTARequestScreening,
AVG(FinalizeSaveToDUKE) as FinalizeSaveToDUKE,
AVG(ClientProductValidation) as ClientProductValidation,
AVG(CallFred) as CallFred,
AVG(rsPricing) as rsPricing,
AVG(rsRace) as rsRace,
AVG(TeaRules) as TeaRules,
AVG(PricingRules) as PricingRules,
AVG(PreCheck) as PreCheck,
AVG(PostCheck) as PostCheck,
AVG([MRAX.Realtime]) as [MRAX.Realtime]
FROM #ClaimTOT


--select * from #ClaimTOT

SET NOCOUNT OFF



