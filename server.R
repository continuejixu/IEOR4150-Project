if ("shiny" %in% rownames(installed.packages()) == FALSE){
  install.packages('shiny')
}
if ("Quandl" %in% rownames(installed.packages()) == FALSE){
  install.packages('Quandl')
}
if ("ggplot2" %in% rownames(installed.packages()) == FALSE){
  install.packages('ggplot2')
}
if ("dplyr" %in% rownames(installed.packages()) == FALSE){
  install.packages('dplyr')
}
if ("sqldf" %in% rownames(installed.packages()) == FALSE){
  install.packages('sqldf')
}
if ("scales" %in% rownames(installed.packages()) == FALSE){
  install.packages('scales')
}
if ("Rmisc" %in% rownames(installed.packages()) == FALSE){
  install.packages('Rmisc')
}
library(shiny)
library(rsconnect)
library(Quandl)
library(ggplot2)
library(dplyr)
library(sqldf)
library(scales)
library(Rmisc)

Quandl.api_key("uUWRMsZQE7cS7Ss1TZWC")
getOil = Quandl("CHRIS/CME_CL1", 
                start_date="2006-01-01", 
                end_date=Sys.Date()
)
getUSD = Quandl("CHRIS/ICE_DX1",
                start_date="2006-01-01", 
                end_date=Sys.Date()
)
getGold = Quandl("CHRIS/CME_GC1",
                 start_date="2006-01-01", 
                 end_date=Sys.Date()
)

mergedata = sqldf("SELECT getGold.Date as Date, getGold.Last as Gold, getOil.Last as Oil, getUSD.Settle as USD
                  FROM getGold, getOil, getUSD
                  WHERE getGold.Date = getOil.Date AND
                  getGold.Date = getUSD.Date")

for (i in 1:nrow(mergedata)) {
  n = log(mergedata$Gold[i+1]/mergedata$Gold[i], base=exp(1))
  mergedata$logGold[i] = n
}
for (i in 1:nrow(mergedata)) {
  m = log(mergedata$Oil[i+1]/mergedata$Oil[i], base=exp(1))
  mergedata$logOil[i] = m
}
for (i in 1:nrow(mergedata)) {
  q = log(mergedata$USD[i+1]/mergedata$USD[i], base=exp(1))
  mergedata$logUSD[i] = q
}

row.has.na = apply(mergedata, 1, function(x){any(is.na(x))})
sum(row.has.na)
mergedata.f = mergedata[!row.has.na,]

##########Above is Data Collection########################
##########################################################
shinyServer(function(input, output) {
  
#Filter date from input
 mergedata.ff <- reactive({subset(mergedata.f,
                                  Date >= input$dates[1],
                                  Date <= input$dates[2])
   })
 

########################Single Analysis#################################  

 output$linechart1 <- renderPlot({
   ggplot(mergedata.ff(),
          aes(x=mergedata.ff()$Date, y=mergedata.ff()[[input$symbol]])) +
     geom_line(colour = "blue") +
     labs(title = paste("Linechart for", input$symbol)) +
     xlab("Date") +
     ylab("") +
     scale_x_date(limits = as.Date(c(input$dates[1],input$dates[2])))
 })
 output$hist1 <- renderPlot({
   hist(mergedata.ff()[[paste0("log",input$symbol)]], main=paste("Histogram for", input$symbol), xlab = "log_return", prob = T)
   #curve(dnorm(x, mean=mean(mergedata[[paste0("log",input$symbol)]]), sd=sd(mergedata[[paste0("log",input$symbol)]])), col = "blue", add=TRUE)
 })
 output$qqplot1 <- renderPlot({
   qqnorm(mergedata.ff()[[paste0("log",input$symbol)]])
   qqline(mergedata.ff()[[paste0("log",input$symbol)]])
 })
 
 cinum = reactive({
   CI(mergedata.ff()[[paste0("log",input$symbol)]], ci = (input$confidence)/100)

   })
 upper = reactive({format(round(cinum()[1],4), scientific = F)})
 lower = reactive({format(round(cinum()[3],4), scientific = F)})
 # upper = reactive({format(round(cinum()[1],4), scientific = F)})
 # lower = reactive({format(round(cinum[3],4), scientific = F)})
 civar = reactive({
   CI(mergedata.ff()[[paste0("log",input$symbol)]]-mean(mergedata.ff()[[paste0("log",input$symbol)]]), ci = (input$confidence)/100)
   #uppervar = format(round(civarnum[1],4), scientific = F)
   #lowervar = format(round(civarnum[3],4), scientific = F)
   })
 uppervar = reactive({format(round(civar()[1],4), scientific = F)})
 lowervar = reactive({
   format(round(civar()[3],4), scientific = F)})

 output$confinterval <- renderText({
   
   paste("The", input$confidence, "% confidence interval of log", input$symbol, "price is: Mean [", lower(), upper(),
        "], Variance [", lowervar(), uppervar(), "].")
 })
 output$reg1 <- renderPlot({
   ggplot(mergedata.ff(), aes(x=mergedata.ff()$Date, y=mergedata.ff()[[paste0("log",input$symbol)]])) +
     geom_point(shape = 1) +
     geom_smooth(method=lm, se = F) +
     labs(title = paste("Linear Regression on", paste0("log",input$symbol), "and Date")) +
     xlab("Date") +
     ylab(paste0("log",input$symbol))
 })
 lm1 <- reactive({
   lm(mergedata.ff()[[paste0("log",input$symbol)]] ~ mergedata.ff()$Date)
 })
 output$textreg1 <- renderPrint({
   summary(lm1())
 })
 output$qqplot2 <- renderPlot({
   qqnorm(lm1()$residuals)
   qqline(lm1()$residuals)
 })
 
 ########################Pairwise Analysis#################################  
 # sym = reactive({
 #   symb = inputsymbol
 # })
 output$linechart2 <- renderPlot({
   ggplot(mergedata.ff(), aes(mergedata.ff()$Date)) +
     geom_line(aes(y = mergedata.ff()[[input$symbol[1]]], colour = input$symbol[1])) +
     geom_line(aes(y = mergedata.ff()[[input$symbol[2]]], colour = input$symbol[2])) +
     scale_x_date(limits = as.Date(c(input$dates[1],input$dates[2])))  +
     labs(title = paste("Line chart for", input$symbol[1], "and", input$symbol[2])) +
     xlab("Date") +
     ylab("")
 })
 
 output$hist2_1 <- renderPlot({
   hist(mergedata.ff()[[paste0("log",input$symbol[1])]], main=paste("Histogram for", input$symbol[1]), xlab = "log_return", prob = T)
 })
 output$hist2_2 <- renderPlot({
   hist(mergedata.ff()[[paste0("log",input$symbol[2])]], main=paste("Histogram for", input$symbol[2]), xlab = "log_return", prob = T)
 })
 ttest <- reactive({
   t.test(mergedata.ff()[[paste0("log",input$symbol[1])]], mergedata.ff()[[paste0("log",input$symbol[2])]], conf.level = (input$confidence)/100)
 })
 output$hypotest <- renderText({
   paste(input$confidence, "% confidence interval is: [", format(round(ttest()$conf.int[1],4)), ",", format(round(ttest()$conf.int[2],4)), 
         "], and P-Value is ", format(round(ttest()$p.value,4)))
 })
 lm2 <- reactive({
   lm(mergedata.ff()[[paste0("log",input$symbol[2])]] ~ mergedata.ff()[[paste0("log",input$symbol[1])]])
 })
 output$reg2 <- renderPlot({
   ggplot(mergedata.ff(), aes(x=mergedata.ff()[[paste0("log",input$symbol[1])]], y=mergedata.ff()[[paste0("log",input$symbol[2])]])) +
     geom_point(shape = 1) +
     geom_smooth(method=lm, se = F) +
     labs(title = paste("Linear Regression on", input$symbol[1], "and", input$symbol[2])) +
     xlab(paste0("log",input$symbol[1])) +
     ylab(paste0("log",input$symbol[2]))
 })
 output$textreg2 <- renderPrint({
   summary(lm2())
 })
 output$qqplot3 <- renderPlot({
   qqnorm(lm2()$residuals)
   qqline(lm2()$residuals)
 }) 
 
########################Threewise Analysis#################################  
 output$linechart3 = renderPlot({
   ggplot(mergedata.ff(), aes(mergedata.ff()$Date)) +
     geom_line(aes(y = mergedata.ff()[[input$symbol[1]]], colour = input$symbol[1])) +
     geom_line(aes(y = mergedata.ff()[[input$symbol[2]]], colour = input$symbol[2])) +
     geom_line(aes(y = mergedata.ff()[[input$symbol[3]]], colour = input$symbol[3])) +
   scale_x_date(limits = as.Date(c(input$dates[1],input$dates[2])))  +
     labs(title = paste("Line Chart for", input$symbol[1], "and", input$symbol[2], "and", input$symbol[3])) +
     xlab("Date") +
     ylab("")
 })
 output$cortable <- renderTable({
   cor(scale(mergedata.ff()[c(2,3,4)]))

 },
 include.rownames = TRUE)
 output$cortable2 <- renderTable({
   cor(mergedata.ff()[c(5,6,7)])

 },
 include.rownames = TRUE)
})
