library(shiny)
library(shinythemes)

shinyUI(fluidPage(theme = shinytheme("united"),
          titlePanel("Correlation Analysis between Gold Price, Crude Oil Price & USD Index"),
          
          sidebarLayout(
            sidebarPanel(
              
              checkboxGroupInput("symbol",label = h4("Select Item(s)"),
                                 choices = list("Gold Price" = "Gold", "Crude Oil Price" ="Oil", "USD Index" = "USD"),
                                 selected = "Gold"),
            br(),
            dateRangeInput("dates", label = h4("Date range"),
                            start = "2011-01-01",
                            end = Sys.Date(),
                            min = "1986-01-01",
                            max = Sys.Date()),
            helpText("Real-time Updated From 2006-01-01"),
            br(),
            sliderInput("confidence", label = h4("Confidence Level"), min = 50, 
                        max = 100, value = 95),
            helpText("Slider for confidence intervals of mean and variance given name of item.")
           
            ),
              mainPanel(
                tabsetPanel(#type = "tabs",
                  
                tabPanel("Single Item Analysis",
                         plotOutput(outputId = "linechart1", height = "400px"),
                         br(),
                         fluidRow(
                           column(10,
                                  plotOutput(outputId = "hist1", height = "300px")),
                           column(10,
                                  plotOutput(outputId = "qqplot1", height = "350px"))
                         ),
                         br(),
                         verbatimTextOutput("confinterval"),
                         br(),
                         fluidRow(
                           column(10,
                                  plotOutput("reg1", height = "400px")),
                           column(10,
                                  plotOutput("qqplot2", height = "400px"))
                         ),
                         verbatimTextOutput("textreg1")
                ),
                tabPanel("Pairwise Analysis",
                         plotOutput(outputId = "linechart2", height = "400px"),
                         br(),
                         fluidRow(
                           column(6,
                                  plotOutput(outputId = "hist2_1", height = "300px")),
                           column(6,
                                  plotOutput(outputId = "hist2_2", height = "300px"))
                         ),
                         br(),
                         helpText("Hypothesis Testing on Two Population Mean", br(),
                                  "H0: Means are equal.", br(),
                                  "H1: Means are not equal."),
                         verbatimTextOutput("hypotest"),
                         fluidRow(
                           column(10,
                                  plotOutput("reg2", height = "400px")),
                           column(10,
                                  plotOutput("qqplot3", height = "400px"))
                         ),
                         verbatimTextOutput("textreg2")
                ),
                tabPanel("Threewise Analysis",
                         plotOutput(outputId = "linechart3", height = "400px"),
                         br(),
                         helpText("Correlation Matrix of Original Price"),
                         tableOutput("cortable"),
                         br(),
                         helpText("Correlation Matrix of log-Price"),
                         tableOutput("cortable2")
                         )
                # tabPanel("Conclusion",
                #          verbatimTextOutput("hypotest2")
                #          )
             )
            )
          )
)
)
                