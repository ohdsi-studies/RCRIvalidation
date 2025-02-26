loadPlpModelGitHub <- function(
    organization = 'ohdsi-studies',
    repo = 'RCRIvalidation',
    folder = 'inst/models/original_rcri'
    ){
  
  plpModel <- list()
  
  # 1) ATTRIBUTES
  attr <- RCurl::getURL(paste0(
    'https://raw.githubusercontent.com/',
    organization, '/', repo, '/refs/heads/main/',
    folder, '/attributes.json'))
  if(attr == "404: Not Found"){
    stop('attributes.json not found - check inputs are correct')
  }
  modelAttributes <- tryCatch(
    ParallelLogger::convertJsonToSettings(attr),
    error = function(e) {
      NULL
    }
  )
  if (is.null(modelAttributes)) {
    stop("Incorrect plpModel object - is this an old model?")
  }
    
  attributes(plpModel) <- modelAttributes
    
  plpModel$covariateImportance <- tryCatch(
      utils::read.csv(
        paste0(
          'https://raw.githubusercontent.com/',
          organization, '/', repo, '/refs/heads/main/',
          folder, '/covariateImportance.csv')
      ),
      error = function(e) {
        NULL
      }
    )
    
  # 2) MODEL
  plpModel$model <- tryCatch(
    ParallelLogger::convertJsonToSettings(
      RCurl::getURL(paste0(
        'https://raw.githubusercontent.com/',
        organization, '/', repo, '/refs/heads/main/',
        folder, '/model.json'))
    )
    , error = function(e) {
      NULL
    }
  )
  
  # 3) MODEL DESIGN
  plpModel$modelDesign <- tryCatch(
    ParallelLogger::convertJsonToSettings(
      RCurl::getURL(paste0(
        'https://raw.githubusercontent.com/',
        organization, '/', repo, '/refs/heads/main/',
        folder, '/modelDesign.json'))
    )
    , error = function(e) {
      NULL
    }
  )
  
  # 4) preprocessing
  plpModel$preprocessing <- tryCatch(
    ParallelLogger::convertJsonToSettings(
      RCurl::getURL(paste0(
        'https://raw.githubusercontent.com/',
        organization, '/', repo, '/refs/heads/main/',
        folder, '/preprocessing.json'))
    )
    , error = function(e) {
      NULL
    }
  )

  # FUTURE
# Have code to figure out what to do about non-glm models
    #if (attr(plpModel, "saveType") == "xgboost") {
    #  rlang::check_installed("xgboost")
    #  plpModel$model <- xgboost::xgb.load(file.path(dirPath, "model.json"))
    #} else if (attr(plpModel, "saveType") == "lightgbm") {
    #  rlang::check_installed("lightgbm")
    #  plpModel$model <- lightgbm::lgb.load(file.path(dirPath, "model.json"))
    #} else if (attr(plpModel, "saveType") %in% c("RtoJson")) {
    #  plpModel$model <- ParallelLogger::loadSettingsFromJson(file.path(dirPath, "model.json"))
    #} else {
    #  plpModel$model <- file.path(dirPath, "model")
    #}
    
    return(plpModel)
  
}


plpModel <- loadPlpModelGitHub()
