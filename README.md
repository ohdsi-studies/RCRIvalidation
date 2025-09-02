RCRIvalidation 
=============

<img src="https://img.shields.io/badge/Study%20Status-Repo%20Created-lightgray.svg" alt="Study Status: Repo Created">

- Analytics use case(s): **Patient-Level Prediction**
- Study type: **Methods Research**
- Tags: **Prediction models**
- Study lead: **Alexander Saelmans**
- Study lead forums tag: **[add](https://forums.ohdsi.org/u/add)**
- Study start date: **02-25-2025**
- Study end date: **-**
- Protocol: **-**
- Publications: **-**
- Results explorer: **-**

Code to run
========

```r


# Set working directory to Renv file
#==========================================#
# Download the Renv lock file from the GitHub page

# Set working directory to the Renv lock file
setwd()
# Check whether the working directory was adjusted
.libPaths()

# Activate Renv
renv::activate()
# Restore R lock file
renv::restore()
# Restart R session
.rs.restartR()

# Inputs to run (edit these for your CDM):
# ========================================= #
# If your database requires temp tables being created in a specific schema
if (!Sys.getenv("DATABASE_TEMP_SCHEMA") == "") {
  options(sqlRenderTempEmulationSchema = Sys.getenv("DATABASE_TEMP_SCHEMA"))
}

# Where to save the output - a directory in your environment
outputFolder <- "./output/folder/"

# Fill in your connection details and path to driver
# See ?DatabaseConnector::createConnectionDetails for help for your 
# database platform
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = Sys.getenv("DBMS"), 
  server = Sys.getenv("DATABASE_SERVER"), 
  user = Sys.getenv("DATABASE_USER"),
  password = Sys.getenv("DATABASE_PASSWORD"),
  port = Sys.getenv("DATABASE_PORT"),
  connectionString = Sys.getenv("DATABASE_CONNECTION_STRING"),
  pathToDriver = Sys.getenv("DATABASE_DRIVER")
) 

# A schema with write access to store cohort tables
workDatabaseSchema <- Sys.getenv("WORK_SCHEMA")
  
# Name of cohort table that will be created for study
cohortTable <- Sys.getenv("COHORT_TABLE")

# Schema where the cdm data is
cdmDatabaseSchema <- Sys.getenv("CDM_SCHEMA")

# Aggregated statistics with cell count less than this are removed before sharing results.
minCellCount <- 5

# =========== END OF INPUTS ========== #

analysisSpecifications <- RCRIvalidation::loadStudySpec()

executionSettings <- Strategus::createCdmExecutionSettings(
  workDatabaseSchema = workDatabaseSchema,
  cdmDatabaseSchema = cdmDatabaseSchema,
  cohortTableNames = CohortGenerator::getCohortTableNames(cohortTable = cohortTable),
  workFolder = file.path(outputFolder, "strategusWork"),
  resultsFolder = file.path(outputFolder, "strategusOutput"),
  minCellCount = minCellCount
)
  
Strategus::execute(
  analysisSpecifications = analysisSpecifications,
  executionSettings = executionSettings,
  connectionDetails = connectionDetails
)

#======================================#
# Don't forget to deactivate your Renv
renv::deactivate()

```

Submitting Results
========

To send the compressed folder results please message Alexander Saelmans (a.saelmans@erasmusmc.nl) and he will give you the privateKeyFileName and userName. You can then run the following R code to share the results:

```r

# This R code demonstrates how a study data site role can upload a local file (for example a results csv gzip file) to the sftp rcriv study folder
# In this example R code a file called "/tmp/results.csv.gz" must exist on the local machine and will be uploaded to the OHDSI sftp server rcriv study folder

#Please upload both the strategusWork and strategusOutput folders
 
# one time R package install
install_github("ohdsi/OhdsiSharing")
 
# upload local file '/tmp/results.csv.gz' to sftp server study folder using the '/tmp/study-data-site-rcriv' data site role private key
 
library("OhdsiSharing")
 
# this data site private key file should only be shared with the study data site users - it must not be shared publicly
privateKeyFileName <- "message us for this"
userName <- "message us for this"
remoteFolder <- "/"
fileName <- "/tmp/results.csv.gz"
sftpUploadFile(privateKeyFileName, userName, remoteFolder, fileName)

# send us the name given to the zip file in the sftp rcriv study folder, so we can access it

```

