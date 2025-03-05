#' @export
loadStudySpec <- function(type = 'validation.json'){
  analysisSpecifications <- ParallelLogger::loadSettingsFromJson(
    fileName = system.file('study_execution_jsons',type,
                           package = 'RCRIvalidation')
    )
  return(analysisSpecifications)
}
