# ###########################################################################
# Second order functions and classes for model fitting 
#
# $Date: 2018-05-08 V2

# Author: Philipp Brun, philipp.brun@wsl.ch
# Dynamic Macroecology Group
# Swiss Federal Research Institute WSL
# 

# ###########################################################################

### =========================================================================
### preparation function
### =========================================================================

preps=function(env=parent.frame(),call){
  
  env=as.list(env)
  
  ### ----------------
  ### check input data
  ### ----------------
  
  if(env$replicatetype%in%c("none","cv","block-cv","splitsample")==FALSE){stop("Non-existing replicatetype!")}
  
  if(env$replicatetype=="block-cv" && is.na(env$strata)){stop("Stratum vector needed for block crossvalidation!")}
  
  if(env$replicatetype=="block-cv" && length(unique(env$strata))!=env$reps){stop("Stratum vector has wrong number of levels!")}
  
  if(env$replicatetype%in%c("cv","block-cv","splitsample")==TRUE && (is.na("reps") ==TRUE || env$reps<2)){stop("Give reasonalbe number of replicates!")}
  
  if(env$replicatetype=="none" && env$reps>1){env$reps=1;warning("Replicate type is 'none' but multiple replicates were chosen - replicates are set to 1")}
  
  
  #check for file path
  if(env$save && is.na(env$project)){stop("supply project in which data should be saved!")}
  
  if(env$save && !(env$project%in%list.dirs(env$path))){stop(paste("Project directory not existing in",env$path,
                                                                   "- please create manually"))} 
  
  ### -------------------
  ### generate wsl.fit obj
  ### -------------------
  
  out<-wsl.fit()
  
  # store function call
  out@call<-call
  
  ### -------------------
  ### add meta.info
  ### -------------------
  
  m.i=list()
  
  m.i$author=Sys.info()[["user"]]
  m.i$date=Sys.time()
  m.i$replicatetype=env$replicatetype
  m.i$replicates=env$reps
  m.i$taxon=env$taxon
  m.i$env_vars=paste(colnames(env$env_vars),collapse=", ")
  m.i$project=env$project
  m.i$model_tag=env$mod_tag
  
  # Add step info if exists
  if("step"%in%names(env)){
    m.i$step=env$step
  }
  
  out@meta=m.i
  
  ### ----------------------
  ### partition observations
  ### ----------------------
  
  # partition observations according to replicate type
  dat=cbind(data.frame(Presence=env$pa),env$env_vars)
  
  obschoice<-list()
  testing<-list()
  if(env$replicatetype=="none"){
    obschoice[[1]]<-dat
    
  } else if (env$replicatetype=="splitsample"){
    for (i in 1:env$reps){
      chc=sample(1:nrow(dat),size=round(nrow(dat)*0.7),replace=FALSE)
      obschoice[[i]]<-dat[chc,]
      testing[[i]]<-dat[-chc,]
    }
    
  } else if (grepl("cv",env$replicatetype)){
    
    if(env$replicatetype=="cv"){
      unistr=sample(1:5,size=nrow(dat),replace=TRUE)      
    } else {
      unistr=env$strata   
    }
    
    for (i in 1:env$reps){
      obschoice[[i]]<-dat[which(unistr!=unique(unistr)[i]),]
      testing[[i]]<-dat[which(unistr==unique(unistr)[i]),]
    }
    
  }
  
  # add testing data to wsl.fit obj
  out@tesdat=testing
  
  # return objects for model fitting
  return(list(wslfi=out,train=obschoice))
}

### =========================================================================
### define multi.input class
### =========================================================================

multi.input<-setClass("multi.input",slots=c(mod="character", # Model function
                                            args="list", # Model function arguments
                                            tag="character", # Model set-up name
                                            step="logical", # Should step function be added?
                                            weight="logical")) # Should observations be weighted?
                                                             # (Applies mainly to GLM)

### =========================================================================
### define multi function
### =========================================================================
# stores information in multi.input object

multi=function(mod,args,tag="",step=FALSE,weight=FALSE){
  
  # Generate multi.input object
  out=multi.input()
  out@tag=tag
  out@step=step
  out@args=args
  out@mod=mod
  out@weight=weight
  
  return(out)
}
