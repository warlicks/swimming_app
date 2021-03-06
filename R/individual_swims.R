# Author: Sean Warlick
# Date: October 12, 2015
# Source Code For Functions to Pull Individual and Relay Data for NCAA Swimming
# from USA Swimming's Website.
###############################################################################

#' Retrive Report From USA Swimming's NCAA DI Top Times Report
#'
#' \code{individual_swims} fills out \href{http://www.usaswimming.org/DesktopDefault.aspx?TabId=1971&Alias=Rainbow&Lang=en}{USA Swimmings Top Times} report form to retrun a top time report.
#'
#' \code{individual_swims} fills out \href{http://www.usaswimming.org/DesktopDefault.aspx?TabId=1971&Alias=Rainbow&Lang=en}{USA Swimmings Top Times} report form to retrun a top time report.  The function fills out form and downloads the as \emph{.csv} file without any human interaction.
#'
#' To fill out the Top Times report form \code{individual_swims()} utilizes \code{\link[RSelenium]{RSelenium}}. RSelenium requires a Selenium Server.  The function automatically checks to make sure that the Selenium Server is installed.  If one is not found it downloads the most recent version.
#'
#' \strong{Note:} the package was developed using Firefox 47.0.1 and Selenium Standalone Server 2.53.1.  It is important to make sure that the server version being used is compatiable with the browser being used.
#'
#' By default the function reads the downlaoded file into memory and stores it as the assigned variable name.  If you select not to read the file into memory it returns the path where the file was saved.
#'
#' The function automatically renames the file downloaded to \emph{confernece.csv}.  If a file with the name \emph{confernce.csv} already exists in chosen directory, it will write over the existing file.
#'
#' @param conf a character string giving name of a Division I conference.
#' @param start_date a character string that defines the begining of the period for the times report. It is entered as a character string in the format 'YYYY-MM-DD'.
#' @param end_date a character string that defines the end of the period for the times report. It is entered as a character string in the format 'YYYY-MM-DD'.
#' @param lcm logical indication if long course meter events be included in the report?. Defaults to FALSE.
#' @param scm logical indicating if should short course meter events be included in the report.  Defaults to FALSE.
#' @param scy logical indicating if short course yard events be included in the report. Defaults to TRUE.
#' @param top integer indicating how many swimmers should be returned in each event.  Default value is top 100 times, while the maximum allowed is 500.
#' @param download_path character sting repersenting a file directory where the returned top times report should be saved.  By default it saves the file to the current working directory.
#' @param read logical indicating if the downloaded file should be loaded into R's memory.
#'
#' @export
#'
#' @return If \emph{read = TRUE} a data frame is returned.  In both cases a \emph{.csv} file is created in the given directory.
#'
#' @seealso \code{\link[RSelenium]{RSelenium}}
#'
#' @examples
#' report <- individual_swims('Big Ten', start_date = '2015-09-01', end_date = '2015-10-01', read = TRUE)
#' report <- individual_swims('Big Ten', start_date = '2015-09-01', end_date = '2015-10-01', read = FALSE)


individual_swims <- function(conf, 
						   start_date = '2015-08-01', 
						   end_date = '2015-05-31', 
						   lcm = FALSE, 
						   scm = FALSE, scy = TRUE, 
						   top = 100, 
						   download_path = getwd(), 
						   read = TRUE){
	require(RSelenium) # Rselenium Provides Tools Fill Out Search Form.

	#checkForServer()

	url <- 'https://legacy.usaswimming.org/DesktopDefault.aspx?TabId=2979'

	#selserv <- startServer(args = c("-port 4445")) # Star Selenium Server

	fprof <- profile(download_path)

	remDr <- remoteDriver(remoteServerAddr = 'localhost', port = 4440, browser = "firefox", extraCapabilities = fprof)

	remDr$open(silent = TRUE)

	remDr$navigate(url)

	time_type <- remDr$findElement(using = "id", value = "ctl02_rbIndividual")
	time_type$clickElement() #Make Sure Indivual Times are Selected

	# Select Conference
	conference_select <- key_press(conf) # Set Up Key Strokes

	conference<-remDr$findElement(using = "id", value = "ctl02_ddConference")
	conference$sendKeysToElement(conference_select) # Pass Key Storkes


	# Select The Courses
	if(lcm == FALSE){
		lcm<-remDr$findElement(using = "id", value = "ctl02_cblCourses_0")
		lcm$clickElement()
	} # Uncheck LCM Button

	if(scm == FALSE){
		scm<-remDr$findElement(using = "id", value = "ctl02_cblCourses_1")
		scm$clickElement()
	} # Uncheck SCM Button

	if(scy == FALSE){
		scy <- remDr$findElement(using = "id", value = "ctl02_cblCourses_2")
		scy$clickElement()
	} # Uncheck SCY Button

	# Set Date Range ----
	date_button <- remDr$findElement(using = "id", value = "ctl02_rbDateRange")
	date_button$clickElement()

	## Start Date
	start_dateBox <- remDr$findElement(using = "id", value = "ctl00_ctl02_ucStartDate_radTheDate_dateInput")
	start_date <- date_parse(start_date)
	start_dateBox$sendKeysToElement(start_date)

	## End Date
	end_dateBox <- remDr$findElement(using = "id", value = "ctl00_ctl02_ucEndDate_radTheDate_dateInput")
	end_date <- date_parse(end_date)
	end_dateBox$sendKeysToElement(end_date)

	# Select How Many Times To Display ----
	## Error Check
	if(top > 500){
		warning("Cannot Excede Top 500 Times")
		stop() # Create Warning and Stop if we excede USA Swimmings Max Value
	}

	## Select top number of time.
	show_top <- remDr$findElement(using = "id", value = "ctl02_txtShowTopX")
	show_top$clearElement()
	show_top$sendKeysToElement(list(as.character(top)))

	# Trun off altitude adjustment ----
	altitude <- remDr$findElement(using = "id", value = "ctl02_cbUseAltitudeAdjTime")
	altitude$clickElement()

	# Submit report search ----
	search <- remDr$findElement(using = "id", value = "ctl02_btnCreateReport")
	search$clickElement()

	Sys.sleep(10)

	# Change The Output To CSV & Save! ----
	output_select <- remDr$findElement(using = "id", value = "ctl02_ucReportViewer_ddViewerType")
	output_select$sendKeysToElement(list("E", "E", "E"))
	change_output <- remDr$findElement(using = "id", value = "ctl02_ucReportViewer_lbChangeOutputType" )

	Sys.sleep(5) # Need to pause to get the export click to work

	change_output$clickElement()

	Sys.sleep(10) # Give Time for Down Load
	remDr$close()

	# File Management ----

	## If working dir is diff from the download path store the current.
	currentwd <- getwd()
	setwd(download_path)

	# Create data frame used to find downloaded file.
	file <- file.info(dir()) 

	#Use create time find name of downloaded file
	file_name <- row.names(file)[which(file$ctime == max(file$ctime))] 

	#Give Meaningful Name

	file.rename(file_name, paste(conf, ".csv", sep = "")) 
	
	if(read){
		data <- read.csv(paste(conf, ".csv", sep = ""), stringsAsFactors = FALSE)
		return(data)
	}

	setwd(currentwd) # Return to working directory

}

