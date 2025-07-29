library(FeatureExtraction)
library(PatientLevelPrediction)
cohortDatabaseSchema <- 'cohortDatabaseSchema'
cohortTableName <- 'cohortTableName'
targetId <- 19684 # ATLAS id for target cohort
outcomeId <- 19683 # ATLAS id for outcome cohort
predictorIds <- c(19685,19695,19687,19690,19686,19691) # ATLAS ids for predictors

# specify the time-at-risk and remove requring full 365 days
populationSettings <- PatientLevelPrediction::createStudyPopulationSettings(
  requireTimeAtRisk = FALSE, 
  riskWindowStart = 1, 
  startAnchor = 'cohort start',
  riskWindowEnd = 30, 
  endAnchor = 'cohort start'
  )

#================================================================================================
#MAPPING FOR THE DIFFERENT MODELS
#================================================================================================

#MAPPING FOR THE ORIGINAL RCRI
RCRIoriginal <- updatedRCRImap <- "function(y){ sapply(y, function(x){
    if(x == 0){
      return(0.004)
    } else if(x == 1){
      return(0.009)
    } else if(x == 2){
      return(0.07)
    } else if(x == 3){
      return(0.11)
    } else if(x > 3){
      return(0.11)
    }
})}"


#MAPPING FOR THE RECALIBRATED RCRI
RCRIrecalibrated <- updatedRCRImap <- "function(x){
  singleMap <- function(x){
    if(x == 0){
      return(0.004)
    } else if(x == 1){
      return(0.009)
    } else if(x == 2){
      return(0.07)
    } else if(x == 3){
      return(0.11)
    } else if(x > 3){
      return(0.11)
    }
  }
  
  result <- sapply(X = x, FUN = singleMap)
  return(result)
}"
  
#=======================================================================================
#CREATE THE MODELS
#=======================================================================================

#ORIGINAL_RCRI
#=======================================================================================
# need to add covariateSettings and stuff to this?
canalysisId <- 668
plpModelOriginal <- PatientLevelPrediction::createGlmModel(
  coefficients = data.frame(
    covariateId = predictorIds*1000+canalysisId,
    coefficient = c(1,1,1,1,1,1)
  ), 
  intercept = 0, 
  mapping = RCRIoriginal,
  populationSettings = populationSettings,
  covariateSettings = list(createCohortCovariateSettings(
      cohortName = 'Covariate RCRI Cerebrovascular disease',
      settingId = 1,
      cohortDatabaseSchema = cohortDatabaseSchema,
      cohortTable = cohortTableName,
      cohortId = 19690, 
      startDay = -9999,
      endDay = 0,
      count = F, 
      ageInteraction = F, 
      analysisId = 668
    ), createCohortCovariateSettings(
      cohortName = 'Covariate RCRI Heart Failure',
      settingId = 1,
      cohortDatabaseSchema = cohortDatabaseSchema,
      cohortTable = cohortTableName,
      cohortId = 19686,  
      startDay = -9999,
      endDay = 0,
      count = F, 
      ageInteraction = F, 
      analysisId = 668
    ), createCohortCovariateSettings(
      cohortName = 'Covariate RCRI Insulin treatment',
      settingId = 1,
      cohortDatabaseSchema = cohortDatabaseSchema,
      cohortTable = cohortTableName,
      cohortId = 19691,  
      startDay = -30,
      endDay = 0,
      count = F, 
      ageInteraction = F, 
      analysisId = 668
    ), createCohortCovariateSettings(
      cohortName = 'Covariate RCRI Ischemic heart disease',
      settingId = 1,
      cohortDatabaseSchema = cohortDatabaseSchema,
      cohortTable = cohortTableName,
      cohortId = 19687, 
      startDay = -9999,
      endDay = 0,
      count = F, 
      ageInteraction = F, 
      analysisId = 668
    ), createCohortCovariateSettings(
      cohortName = 'Covariate RCRI Elevated risk surgery',
      settingId = 1,
      cohortDatabaseSchema = cohortDatabaseSchema,
      cohortTable = cohortTableName,
      cohortId = 19685, 
      startDay = -30,
      endDay = 0,
      count = F, 
      ageInteraction = F, 
      analysisId = 668
    ), createCohortCovariateSettings(
      cohortName = 'Covariate RCRI Creatinine including renal impairment',
      settingId = 1,
      cohortDatabaseSchema = cohortDatabaseSchema,
      cohortTable = cohortTableName,
      cohortId = 19695, 
      startDay = -9999,
      endDay = 0,
      count = F, 
      ageInteraction = F, 
      analysisId = 668
    )
    )
)

plpModelOriginal$modelDesign$targetId <- targetId
plpModelOriginal$modelDesign$outcomeId <- outcomeId
plpModelOriginal$modelDesign$covariateSettings <- list(
  FeatureExtraction::createCohortBasedCovariateSettings(
  analysisId = canalysisId,
  covariateCohortDatabaseSchema = '', 
  covariateCohortTable = '', 
  covariateCohorts = data.frame(
    cohortId = predictorIds,
    cohortName = c('Elevated risk surgery','Renal impairment creatinine','Ischemic heart disease','Cerebrovascular disease','Heart failure','Insulin')
    ), 
  valueType = 'binary', 
  startDay = -365, 
  endDay = 0
  ),
  FeatureExtraction::createCovariateSettings(
    useDemographicsAge = T
    )
)

# bug that needs fixing in PLP
attr(plpModelOriginal,"saveType") <- 'RtoJson'

# RtoJson
PatientLevelPrediction::savePlpModel(
  plpModel = plpModelOriginal, 
  dirPath = './inst/models/original_rcri'
    )

#OMOPED_RCRI
#=============================================================================================
canalysisId <- 668
plpModelOMOP <- PatientLevelPrediction::createGlmModel(
  coefficients = data.frame(
    covariateId = predictorIds*1000+canalysisId,
    coefficient = c(1,1,1,1,1,1)
  ), 
  intercept = 0, 
  mapping = "logistic",
  populationSettings = populationSettings,
  covariateSettings = list(createCohortCovariateSettings(
      cohortName = 'Covariate RCRI Cerebrovascular disease',
      settingId = 1,
      cohortDatabaseSchema = cohortDatabaseSchema,
      cohortTable = cohortTableName,
      cohortId = 19690, 
      startDay = -9999,
      endDay = 0,
      count = F, 
      ageInteraction = F, 
      analysisId = 668
    ), createCohortCovariateSettings(
      cohortName = 'Covariate RCRI Heart Failure',
      settingId = 1,
      cohortDatabaseSchema = cohortDatabaseSchema,
      cohortTable = cohortTableName,
      cohortId = 19686,  
      startDay = -9999,
      endDay = 0,
      count = F, 
      ageInteraction = F, 
      analysisId = 668
    ), createCohortCovariateSettings(
      cohortName = 'Covariate RCRI Insulin treatment',
      settingId = 1,
      cohortDatabaseSchema = cohortDatabaseSchema,
      cohortTable = cohortTableName,
      cohortId = 19691,  
      startDay = -30,
      endDay = 0,
      count = F, 
      ageInteraction = F, 
      analysisId = 668
    ), createCohortCovariateSettings(
      cohortName = 'Covariate RCRI Ischemic heart disease',
      settingId = 1,
      cohortDatabaseSchema = cohortDatabaseSchema,
      cohortTable = cohortTableName,
      cohortId = 19687, 
      startDay = -9999,
      endDay = 0,
      count = F, 
      ageInteraction = F, 
      analysisId = 668
    ), createCohortCovariateSettings(
      cohortName = 'Covariate RCRI Elevated risk surgery',
      settingId = 1,
      cohortDatabaseSchema = cohortDatabaseSchema,
      cohortTable = cohortTableName,
      cohortId = 19685, 
      startDay = -30,
      endDay = 0,
      count = F, 
      ageInteraction = F, 
      analysisId = 668
    ), createCohortCovariateSettings(
      cohortName = 'Covariate RCRI Creatinine including renal impairment',
      settingId = 1,
      cohortDatabaseSchema = cohortDatabaseSchema,
      cohortTable = cohortTableName,
      cohortId = 19695, 
      startDay = -9999,
      endDay = 0,
      count = F, 
      ageInteraction = F, 
      analysisId = 668
    )
    )
)

plpModelOMOP$modelDesign$targetId <- targetId
plpModelOMOP$modelDesign$outcomeId <- outcomeId
plpModelOMOP$modelDesign$covariateSettings <- list(
  FeatureExtraction::createCohortBasedCovariateSettings(
  analysisId = canalysisId,
  covariateCohortDatabaseSchema = '', 
  covariateCohortTable = '', 
  covariateCohorts = data.frame(
    cohortId = predictorIds,
    cohortName = c('Elevated risk surgery','Renal impairment creatinine','Ischemic heart disease','Cerebrovascular disease','Heart failure','Insulin')
    ), 
  valueType = 'binary', 
  startDay = -365, 
  endDay = 0
  ),
  FeatureExtraction::createCovariateSettings(
    useDemographicsAge = T
    )
)

# bug that needs fixing in PLP
attr(plpModelOMOP,"saveType") <- 'RtoJson'

# RtoJson
PatientLevelPrediction::savePlpModel(
  plpModel = plpModelOMOP, 
  dirPath = './inst/models/omoped_rcri'
    )

#RECALIBRATED_RCRI
#============================================================================
  canalysisId <- 668
plpModelRecal <- PatientLevelPrediction::createGlmModel(
  coefficients = data.frame(
    covariateId = predictorIds*1000+canalysisId,
    coefficient = c(1,1,1,1,1,1)
  ), 
  intercept = 0, 
  mapping = RCRIrecalibrated,
  populationSettings = populationSettings,
  covariateSettings = list(createCohortCovariateSettings(
      cohortName = 'Covariate RCRI Cerebrovascular disease',
      settingId = 1,
      cohortDatabaseSchema = cohortDatabaseSchema,
      cohortTable = cohortTableName,
      cohortId = 19690, 
      startDay = -9999,
      endDay = 0,
      count = F, 
      ageInteraction = F, 
      analysisId = 668
    ), createCohortCovariateSettings(
      cohortName = 'Covariate RCRI Heart Failure',
      settingId = 1,
      cohortDatabaseSchema = cohortDatabaseSchema,
      cohortTable = cohortTableName,
      cohortId = 19686,  
      startDay = -9999,
      endDay = 0,
      count = F, 
      ageInteraction = F, 
      analysisId = 668
    ), createCohortCovariateSettings(
      cohortName = 'Covariate RCRI Insulin treatment',
      settingId = 1,
      cohortDatabaseSchema = cohortDatabaseSchema,
      cohortTable = cohortTableName,
      cohortId = 19691,  
      startDay = -30,
      endDay = 0,
      count = F, 
      ageInteraction = F, 
      analysisId = 668
    ), createCohortCovariateSettings(
      cohortName = 'Covariate RCRI Ischemic heart disease',
      settingId = 1,
      cohortDatabaseSchema = cohortDatabaseSchema,
      cohortTable = cohortTableName,
      cohortId = 19687, 
      startDay = -9999,
      endDay = 0,
      count = F, 
      ageInteraction = F, 
      analysisId = 668
    ), createCohortCovariateSettings(
      cohortName = 'Covariate RCRI Elevated risk surgery',
      settingId = 1,
      cohortDatabaseSchema = cohortDatabaseSchema,
      cohortTable = cohortTableName,
      cohortId = 19685, 
      startDay = -30,
      endDay = 0,
      count = F, 
      ageInteraction = F, 
      analysisId = 668
    ), createCohortCovariateSettings(
      cohortName = 'Covariate RCRI Creatinine including renal impairment',
      settingId = 1,
      cohortDatabaseSchema = cohortDatabaseSchema,
      cohortTable = cohortTableName,
      cohortId = 19695, 
      startDay = -9999,
      endDay = 0,
      count = F, 
      ageInteraction = F, 
      analysisId = 668
    )
    )
)

plpModelRecal$modelDesign$targetId <- targetId
plpModelRecal$modelDesign$outcomeId <- outcomeId
plpModelRecal$modelDesign$covariateSettings <- list(
  FeatureExtraction::createCohortBasedCovariateSettings(
  analysisId = canalysisId,
  covariateCohortDatabaseSchema = '', 
  covariateCohortTable = '', 
  covariateCohorts = data.frame(
    cohortId = predictorIds,
    cohortName = c('Elevated risk surgery','Renal impairment creatinine','Ischemic heart disease','Cerebrovascular disease','Heart failure','Insulin')
    ), 
  valueType = 'binary', 
  startDay = -365, 
  endDay = 0
  ),
  FeatureExtraction::createCovariateSettings(
    useDemographicsAge = T
    )
)

# bug that needs fixing in PLP
attr(plpModelRecal,"saveType") <- 'RtoJson'

# RtoJson
PatientLevelPrediction::savePlpModel(
  plpModel = plpModelRecal, 
  dirPath = './inst/models/recalibrated_rcri'
    )

  


