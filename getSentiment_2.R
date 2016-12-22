library(syuzhet)
library(dplyr)
library(lubridate)
library(pbapply)
library(ggplot2)
library(reshape2)
library(forecast)
#Load Data
load("~/Dropbox/R Projects/CC_Scrape/data_grouped.Rda")



#story_links_all_df_grouped = story_links_all_df_grouped %>% filter(date != ymd("2014-02-19"))

#Group stories by date
#story_links_all_df_grouped = story_links_all_df %>% group_by(date) %>%
#  summarise(text_grouped = toString(text))

#save(story_links_all_df_grouped,file="/Users/Choche/Dropbox/R Projects/CC_Scrape/data_grouped.Rda")




getEmotions = function(row){
  
  sentences = get_sentences(row[2])
  emotions = get_nrc_sentiment(sentences)
  emotions_sum = data.frame(t(colSums(prop.table(emotions[,]))))
  
  print(row[1])
  
  emotions_sum$date = row[1]
  return(emotions_sum)
}

emotions_all_list = pbapply(story_links_all_df_grouped, 2, getEmotions)

emotions_all_df = do.call("rbind",emotions_all_list)
emotions_all_df = emotions_all_df[complete.cases(emotions_all_df),]

days = 90

emotions_results_normalized = data.frame(cbind(date=emotions_all_df$date,
                                               do.call("cbind",
                                                       lapply(emotions_all_df[,-11],
                                                              function(x) (x-mean(x))/sd(x)))))

emotions_results_normalized$date = ymd(emotions_results_normalized$date)
emotions_results_normalized[,-1] = sapply(emotions_results_normalized[,-1],
                                          function(x) as.numeric(as.character(x)))

mav <- function(x,n=5){stats::filter(x,rep(1/n,n), sides=2)}

emotions_results_normalized[,-1] = mav((emotions_results_normalized[,-1]),n=days)
emotions_results_normalized = na.omit(emotions_results_normalized)

emotions_melt = melt(emotions_results_normalized,id.vars = "date")

ggplot(emotions_melt,aes(x=date,y=value,colour=variable)) + 
  geom_line() + facet_wrap(~variable) + ggtitle(paste("Caracas Chronicles' Normalized \n",days," Days Moving Average Sentiment Score"))


