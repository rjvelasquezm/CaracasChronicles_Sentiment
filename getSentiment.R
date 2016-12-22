library(syuzhet)
library(dplyr)
library(lubridate)
library(pbapply)
library(ggplot2)

#Load Data
load("~/Dropbox/R Projects/CC_Scrape/data_grouped.Rda")


test = story_links_all_df_grouped %>% filter(date == ymd("2014-02-19"))
write.csv(test)

story_links_all_df_grouped = story_links_all_df_grouped %>% filter(date != ymd("2014-02-19"))

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

emotions_all_list = pbapply(story_links_all_df_grouped, 1, getEmotions)

emotions_all_df = do.call("rbind",emotions_all_list)
emotions_all_df = emotions_all_df[complete.cases(emotions_all_df),]

emotions_results_normalized = data.frame(cbind(date=emotions_all_df$date,
                                               do.call("cbind",
                                                       lapply(emotions_all_df[,-11],
                                                              function(x) (x-mean(x))/sd(x)))))


emotions_melt = melt(emotions_results_normalized,id.vars = "date")

ggplot(emotions_melt,aes(x=date,y=value,colour=variable)) + 
  geom_line() + facet_wrap(~variable)


