library(data.table)   # Required for rbindlist
library(dplyr)        # Required to use the pipes %>% and some table manipulation commands
library(magrittr)     # Required to use the pipes %>%
library(rvest)        # Required for read_html
library(RSelenium)    # Required for webscraping with 
library(RCurl)
library(XML)
library(stringr)
library(lubridate)
library(pbapply)

# Grab Links For Stories --------------------------------------------------
pages_length = 2:175

link_pages_link = pbsapply(pages_length, function(x) paste0("http://www.caracaschronicles.com/category/politics/page/",x,"/"))

grabLinks = function(url){
  
  html <- paste(readLines(url), collapse="\n")
  
  matched <- str_match_all(html, "<a href=\"(.*?)\"")
  links <- matched[[1]][, 2]
  
  reg_str = "20[0-9][0-9]/[0-9][0-9]/[0-9][0-9]/.*/$"
  
  vec = str_detect(links,reg_str)
  
  story_links = data.frame(link=as.character(links[vec]))
  story_links$date = ymd(str_extract_all(story_links$link,reg_str))
  story_links$link = as.character(story_links$link)
  
  return(story_links)
  
}

story_links_all = pblapply(link_pages_link, grabLinks)

story_links_all_df = unique(do.call("rbind",story_links_all))

# Grab Text From Each Story -----------------------------------------------

grabText = function(link){
 
  print(link)
  story_text = tryCatch(link %>% read_html() %>% 
    html_nodes(".td-post-content p , .td-post-content div") %>% html_text(),error = function(e) NULL)
  
  
  
  return(story_text)
  }


story_links_all_df$text = pbsapply(story_links_all_df$link, grabText)

#save(story_links_all_df,file="/Users/Choche/Dropbox/R Projects/CC_Scrape/data.Rda")


story_links_all_df_grouped = story_links_all_df %>% group_by(date) %>%
  summarise(text_grouped = toString(text))



