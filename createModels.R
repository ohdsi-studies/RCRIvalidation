# create the models

# need to add covariateSettings and stuff to this?
canalysisId <- 668
plpModel <- PatientLevelPrediction::createGlmModel(
  coefficients = data.frame(
    covariateId = c(1002, predictorIds*1000+canalysisId),
    coefficient = rep(1, 1+length(predictorIds))
  ), 
  intercept = 12, 
  mapping = "logistic"#,
  # need to add
  ##targetId, 
  ##outcomeId,
  ##covariateSettings
    )

plpModel$modelDesign$targetId <- targetId
plpModel$modelDesign$outcomeId <- outcomeId
plpModel$modelDesign$covariateSettings <- list(
  FeatureExtraction::createCohortBasedCovariateSettings(
  analysisId = canalysisId,
  covariateCohortDatabaseSchema = '', 
  covariateCohortTable = '', 
  covariateCohorts = data.frame(
    cohortId = predictorIds,
    cohortName = c('predictor1','predictor2','predictor3','predictor4','predictor5')
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
attr(plpModel,"saveType") <- 'RtoJson'

# RtoJson
PatientLevelPrediction::savePlpModel(
  plpModel = plpModel, 
  dirPath = './inst/models/original_rcri'
    )


