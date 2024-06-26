.onLoad <- function(libname, pkgname) {
  utils::data(Mouse_Cancer_labeling_matrix, package = pkgname, envir = parent.env(environment()))
  Mouse_Cancer_labeling_matrix <- SSMD::Mouse_Cancer_labeling_matrix
  assign("Mouse_Cancer_labeling_matrix", Mouse_Cancer_labeling_matrix, envir = parent.env(environment()))
  
  utils::data(Mouse_Cancer_core_marker, package = pkgname, envir = parent.env(environment()))
  Mouse_Cancer_core_marker <- SSMD::Mouse_Cancer_core_marker
  assign("Mouse_Cancer_core_marker", Mouse_Cancer_core_marker, envir = parent.env(environment()))
  
  utils::data(Mouse_hematopoietic_labeling_matrix, package = pkgname, envir = parent.env(environment()))
  Mouse_hematopoietic_labeling_matrix <- SSMD::Mouse_hematopoietic_labeling_matrix
  assign("Mouse_hematopoietic_labeling_matrix", Mouse_hematopoietic_labeling_matrix, envir = parent.env(environment()))
  
  utils::data(Mouse_hematopoietic_core_marker, package = pkgname, envir = parent.env(environment()))
  Mouse_hematopoietic_core_marker <- SSMD::Mouse_hematopoietic_core_marker
  assign("Mouse_hematopoietic_core_marker", Mouse_hematopoietic_core_marker, envir = parent.env(environment()))
  
  utils::data(Mouse_Brain_labeling_matrix, package = pkgname, envir = parent.env(environment()))
  Mouse_Brain_labeling_matrix <- SSMD::Mouse_Brain_labeling_matrix
  colnames(Mouse_Brain_labeling_matrix) <- c("Astrocyte", "Endothelial", "Ependymal", "Stromal", "Oligodendrocyte", "Microglial", "Glial", "Neuron", "Schwann")
  assign("Mouse_Brain_labeling_matrix", Mouse_Brain_labeling_matrix, envir = parent.env(environment()))

  utils::data(Mouse_Brain_core_marker, package = pkgname, envir = parent.env(environment()))
  Mouse_Brain_core_marker <- SSMD::Mouse_Brain_core_marker
  names(Mouse_Brain_core_marker) <- c("Ependymal", "Microglial", "Oligodendrocyte", "Stromal", "Endothelial", "Schwann", "Glial", "Neuron", "Astrocyte")
  assign("Mouse_Brain_core_marker", Mouse_Brain_core_marker, envir = parent.env(environment()))

  
  utils::data(Mouse_Blood_core_marker, package = pkgname, envir = parent.env(environment()))
  Mouse_Blood_core_marker <- SSMD::Mouse_Blood_core_marker
  assign("Mouse_Blood_core_marker", Mouse_Blood_core_marker, envir = parent.env(environment()))
  
  utils::data(Mouse_Blood_labeling_matrix, package = pkgname, envir = parent.env(environment()))
  Mouse_Blood_labeling_matrix <- SSMD::Mouse_Blood_labeling_matrix
  assign("Mouse_Blood_labeling_matrix", Mouse_Blood_labeling_matrix, envir = parent.env(environment()))

  utils::data(Mouse_human_mapping, package = pkgname, envir = parent.env(environment()))
  Mouse_human_mapping <- SSMD::Mouse_human_mapping
  assign("Mouse_human_mapping", Mouse_human_mapping, envir = parent.env(environment()))
  
}


SSMD <- function(bulk_data,tissue) {
  
  data11=bulk_data
  
  BCV_ttest2 <- function(data0, rounds = 20, slice0 = 2, maxrank0 = 4, msep_cut = 0.01) {
    x <- data0
    fff_cc <- c()
    for (kk in 1:rounds) {
      cv_result <- bcv::cv.svd.gabriel(x, slice0, slice0, maxrank = maxrank0)
      fff_cc <- rbind(fff_cc, cv_result$msep)
    }
    fff_cc[is.na(fff_cc)]=0
    pp <- c()
    ddd <- apply(fff_cc, 2, mean)
    ddd <- ddd/sum(ddd)
    for (kk in 1:(ncol(fff_cc) - 1)) {
      pp_c <- 1
      if (mean(fff_cc[, kk], na.rm = T) > mean(fff_cc[, kk + 1], na.rm = T)) {
        if (ddd[kk] > msep_cut) {
          pp_c <- stats::t.test(fff_cc[, kk], fff_cc[, kk + 1])$p.value
        }
      }
      pp <- c(pp, pp_c)
    }
    return(list(pp, fff_cc))
  }
  
  
  ############################
  
  
  # caculate the base in selected list
  Compute_Rbase_SVD_addSigMat <- function (bulk_data, tg_R1_lists_selected) 
  { 
    SSMD_module_keep_gene=c()
    for (j in 1:length(tg_R1_lists_selected)) {
      SSMD_module_keep_gene=c(SSMD_module_keep_gene,tg_R1_lists_selected[[j]])
    }
    SSMD_module_keep_gene=unique(SSMD_module_keep_gene)
    
    tg_R1_lists_st_ccc <- tg_R1_lists_selected
    data_c <- bulk_data
    Base_all <- c()
    each_module_length <- length(tg_R1_lists_st_ccc[[1]]) #assume every module has same length
    module_size <- length(tg_R1_lists_st_ccc)
    Sig_all <- matrix(0, length(SSMD_module_keep_gene), module_size)
    rownames(Sig_all)=SSMD_module_keep_gene
    gene_all <- c()
    for (i in 1:length(tg_R1_lists_st_ccc)) {
      tg_data_c <- data_c[tg_R1_lists_st_ccc[[i]], ]
      gene_all <- c(gene_all, tg_R1_lists_st_ccc[[i]])
      svd_result <- svd(tg_data_c)
      cc <- svd_result$v[, 1]
      ss <- svd_result$u[, 1] * svd_result$d[1] # u[,1]* d_max
      ccc <- cor(cc, t(tg_data_c))
      if (mean(ccc) < 0) {
        cc <- -cc
        ss <- -ss
      }
      Base_all <- rbind(Base_all, cc)
      Sig_all[tg_R1_lists_st_ccc[[i]], i] <- ss 
    }
    
    rownames(Base_all) <- 1:nrow(Base_all)
    if (length(names(tg_R1_lists_selected)) > 1) {
      rownames(Base_all) <- names(tg_R1_lists_selected)
      colnames(Base_all)=colnames(bulk_data)
    }
    #Base_all=t(Base_all)
    
    #rownames(Sig_all) <- gene_all
    colnames(Sig_all) <- names(tg_R1_lists_st_ccc)
    
    return(list(Base_all=Base_all, Sig_all=Sig_all)) # Prop, Signature 
  }
  
  
  Compute_Rbase_SVD <- function(bulk_data, tg_R1_lists_selected) {
    tg_R1_lists_st_ccc <- tg_R1_lists_selected
    data_c <- bulk_data
    Base_all <- c()
    for (i in 1:length(tg_R1_lists_st_ccc)) {
      tg_data_c <- data_c[tg_R1_lists_st_ccc[[i]], ]
      cc <- svd(tg_data_c)$v[, 1]
      ccc <- stats::cor(cc, t(tg_data_c))
      if (mean(ccc) < 0) {
        cc <- -cc
      }
      Base_all <- rbind(Base_all, cc)
    }
    rownames(Base_all) <- 1:nrow(Base_all)
    if (length(names(tg_R1_lists_selected)) > 0) {
      rownames(Base_all) <- names(tg_R1_lists_selected)
    }
    return(Base_all)
  }
  

  # converting mouse symbol into human symbol
  tran_core <- function(core) {
    mylist <- list()
	for (z in names(core)){
	  Mouse_human_mapping <- as.data.frame(Mouse_human_mapping)
	  values = core[[z]]
	  human_core <- subset(Mouse_human_mapping, V5 %in% values)
	  human_core <- distinct(human_core, V1,.keep_all=TRUE)
	  mylist[[z]] <- human_core$V1
	}
	return(mylist)
  }

  tran_labeling <- function(labeling) {
	  Mouse_human_mapping <- as.data.frame(Mouse_human_mapping)
	  labeling_df <- as.data.frame(labeling)
	  merged_data <- merge(labeling_df, Mouse_human_mapping, by.x = "row.names", by.y = "V5", all = FALSE)
	  merged_data <- distinct(merged_data, V1,.keep_all=TRUE)
	  rownames(merged_data) <- merged_data$V1
	  merged_data <- merged_data[, colnames(labeling)]
	  merged_matrix <- as.matrix(merged_data)
	return(merged_matrix)
  }

  #################
  if (tissue=='Inflammatory'){
    tg_core_marker_set=Mouse_Cancer_core_marker
    marker_stats1_uni=Mouse_Cancer_labeling_matrix
  }
  if (tissue=='Inflammatory_h'){
    tg_core_marker_set=tran_core(Mouse_Cancer_core_marker)
    marker_stats1_uni=tran_labeling(Mouse_Cancer_labeling_matrix)
  }
  if (tissue=='Central Nervous System'){
    tg_core_marker_set = SSMD::Mouse_Brain_core_marker
    marker_stats1_uni = SSMD::Mouse_Brain_labeling_matrix
  }  
  if (tissue=='Central Nervous System_h'){
    tg_core_marker_set = tran_core(SSMD::Mouse_Brain_core_marker)
    marker_stats1_uni = tran_labeling(SSMD::Mouse_Brain_labeling_matrix)
  } 
  if (tissue=='Hematopoietic System'){
    tg_core_marker_set=Mouse_hematopoietic_core_marker
    marker_stats1_uni=Mouse_hematopoietic_labeling_matrix
  }
  if (tissue=='Hematopoietic System_h'){
    tg_core_marker_set=tran_core(Mouse_hematopoietic_core_marker)
    marker_stats1_uni=tran_labeling(Mouse_hematopoietic_labeling_matrix)
  }
  if (tissue=='Blood'){
    tg_core_marker_set=Mouse_Blood_core_marker
    marker_stats1_uni=Mouse_Blood_labeling_matrix
  } 
  if (tissue=='Blood_h'){
    tg_core_marker_set=tran_core(Mouse_Blood_core_marker)
    marker_stats1_uni=tran_labeling(Mouse_Blood_labeling_matrix)
  }
  cell_type = names(tg_core_marker_set)
  i = 1
  intersect_marker1 = vector("list")
  for (cell in cell_type) {
    name = cell
    if (cell == "T") {
      tg_marker <- names(which(marker_stats1_uni[, "CD4T"] >= 1 | marker_stats1_uni[, "CD8T"] >= 1 | marker_stats1_uni[, "T"] >= 1))
    } else {
      tg_marker <- names(which((marker_stats1_uni[, cell] >= 1)))
    }
    intersect_marker1[[i]] = intersect(tg_marker, rownames(data11))
    names(intersect_marker1)[[i]] = name
    i = i + 1
  }
  
  #######################
  intersect_marker1_choose = vector("list", length = length(intersect_marker1))
  for (i in 1:length(intersect_marker1)) {
    intersect_marker1_choose[i] = intersect_marker1[i]
  }
  names(intersect_marker1_choose) = names(intersect_marker1)
  intersect_marker1_choose[sapply(intersect_marker1_choose, is.null)] = NULL
  
  
  ################
  
  infor.list = vector("list", length(intersect_marker1_choose))
  marker_modules = vector("list")
  
  for (i in 1:length(intersect_marker1_choose)) {
    
    name=names(intersect_marker1_choose)[i]
    data_c<-data11[intersect(rownames(data11),intersect_marker1_choose[[i]]),]
    
    corr=cor(t(data_c))
    corr[sapply(corr, is.na)] = 0
    
    
    if(dim(corr)[1]<100){
      thr=0.6
    }else{
      ###gene size must be large enough
      
      invisible(capture.output(res <- rm.get.threshold(corr,interactive =F,plot.spacing =F,plot.comp =F,save.fit=F,interval=c(0.4,max(abs(corr[which(corr!=1)]))))))
      #suppressWarnings()
      invisible(capture.output(dis <- res$tested.thresholds[which(res$dist.Expon>res$dist.Wigner & res$tested.thresholds>0.6)][1]))
      
      if ( is.na(dis) ){
        dis=0
      }
      invisible(capture.output(p.ks <- res$tested.thresholds[which(res$p.ks>0.05)][1]))
    
      if ( is.na(p.ks) ){
        p.ks=0
      }
      thr=max(dis,p.ks,0.6)
    }
    ######
    # print('##################')
    # print(thr)
    # print('##################')
    invisible(capture.output(cleaned.matrix <- rm.denoise.mat(corr, threshold = thr, keep.diag = TRUE)))
    clust=hclust(dist(cleaned.matrix))
    
    written_list=rep(0, dim(corr)[1])
    names(written_list)=row.names(corr)
    n=1
    cut_value=2
    t=cutree(clust, k = cut_value)
    keep_k=vector("list",cut_value)
    marker_modules_cell_type=vector("list")
    marker_modules_length=1
    
    while(cut_value<length(clust$order))
    {
      t=cutree(clust, k = cut_value)
      for (k in 1:cut_value) {
        d=t[which(t==k)]
        mean=mean(abs(corr[names(d),names(d)]))
        #print(mean)
        
        if ( mean>=thr & length(d) >= 6 ){
          if (sum(written_list[names(d)])==0){
            keep_sample=names(d)
            written_list[keep_sample]=n
            n=n+1
            # print(d)
            # print(mean)
            keep_corr=mean
            keep_sample=names(d)
            marker_modules_cell_type[[marker_modules_length]]=names(d)
            marker_modules_length=marker_modules_length+1
            keep_k[[k]]=keep_sample
            #print(mean)
          }
        }
      }  
      
      #t=cutree(clust, k = cut_value)
      cut_value=cut_value+1
    }
    
    keep_k[sapply(keep_k, is.null)] = NULL
    
    infor.list[[i]]=list(name, keep_k)
    marker_modules[[i]]=marker_modules_cell_type
    if(length(marker_modules_cell_type)!=0){
      for (t in 1:length(marker_modules[[i]])) {
        names(marker_modules[[i]])[t]=paste(name,t,sep = '_')
      }
    }else{
      marker_modules[[i]]=NULL
    }
    
  }
  marker_modules[sapply(marker_modules, is.null)] = NULL
  
  ###############
  marker_modules_plain <- list()
  nn <- c()
  N <- 0
  for (i in 1:length(marker_modules)) {
    for (j in 1:length(marker_modules[[i]])) {
      N <- N + 1
      marker_modules_plain[[N]] <- marker_modules[[i]][[j]]
    }
    nn <- c(nn, names(marker_modules[[i]]))
  }
  names(marker_modules_plain) <- nn
  
  ################
  Stat_all <- as.data.frame(nn)
  aa <- c()
  for (i in 1:length(nn)) {
    aa <- rbind(aa, unlist(strsplit(nn[i], "_")))
  }
  Stat_all$CT <- aa[, 1]
  Stat_all$CTN <- as.numeric(aa[, 2])
  colnames(Stat_all)[1] <- "ID"
  
  mean_value = list()
  Core_overlap_number = list()
  Core_overlap_rate = list()
  BCV_rank = list()
  
  for (i in 1:length(marker_modules_plain)) {
    ############
    data0 = data11[marker_modules_plain[[i]], ]
    corr = stats::cor(t(data0))
    mean_value[[i]] = mean(corr)
    #####################
    gene_name = sapply(names(marker_modules_plain)[i], function(y) strsplit(y, split = "_")[[1]][[1]])
    core_marker = tg_core_marker_set[[which(names(tg_core_marker_set) == gene_name)]]
    interaction_marker = intersect(core_marker, marker_modules_plain[[i]])
    Core_overlap_number[[i]] = length(interaction_marker)
    Core_overlap_rate[[i]] = (length(interaction_marker)/length(marker_modules_plain[[i]]))
    BCV = BCV_ttest2(data0, maxrank0 = 10)
    BCV_rank[[i]] = mean(BCV[[2]][, 1]/apply(BCV[[2]], 1, sum))
  }
  
  Stat_all$mean = mean_value
  Stat_all$Core_overlap_number = Core_overlap_number
  Stat_all$Core_overlap_rate = Core_overlap_rate
  Stat_all$BCV_rank = BCV_rank
  
  j = 1
  module_keep = vector("list")
  for (module_cell in unique(Stat_all$CT)) {
    aaa = Stat_all[which(Stat_all$CT == module_cell), ]
    bbb = aaa$ID[which((aaa$Core_overlap_number == max(max(unlist(aaa$Core_overlap_number)),2))|(aaa$Core_overlap_number>=10)
                       |((aaa$Core_overlap_number>=5)&(aaa$Core_overlap_rate>=0.5)))]
    module_keep[[j]] =marker_modules_plain[which(names(marker_modules_plain) %in% bbb)]
    j = j + 1
  }
  #module_keep[sapply(module_keep, is.null)] = NULL
  module_keep_plain <- list()
  nn <- c()
  N <- 0
  for (i in 1:length(module_keep)) {
    if(length(module_keep[[i]])>0){
      for (j in 1:length(module_keep[[i]])) {
        N <- N + 1
        module_keep_plain[[N]] <- module_keep[[i]][[j]]
      }
      nn <- c(nn, names(module_keep[[i]]))
    }
  }
  names(module_keep_plain) <- nn
  
  # aaa <- Compute_Rbase_SVD(data11, module_keep) get propotion for selected modules
  combine_uv <- Compute_Rbase_SVD_addSigMat(data11, module_keep_plain)
  Prop <- combine_uv[[1]]
  sig_matrix <- combine_uv[[2]]
  
  ####################################
  #add function: print out modules
  left_genes=setdiff(unlist(intersect_marker1_choose),unlist(module_keep_plain))
  data_c<-data11[intersect(rownames(data11),left_genes),]
  
  corr=cor(t(data_c))
  corr[sapply(corr, is.na)] = 0
  clust=hclust(dist(corr))
  
  written_list=rep(0, dim(corr)[1])
  names(written_list)=row.names(corr)
  n=1
  cut_value=2
  t=cutree(clust, k = cut_value)
  keep_k=vector("list",cut_value)
  marker_modules_non=vector("list")
  marker_modules_non_length=1
  
  while(cut_value<length(clust$order))
  {
    t=cutree(clust, k = cut_value)
    for (k in 1:cut_value) {
      d=t[which(t==k)]
      mean=mean(abs(corr[names(d),names(d)]))
      #print(mean)
      
      if ( mean>=0.8 & length(d) >= 10 ){
        if (sum(written_list[names(d)])==0){
          keep_sample=names(d)
          written_list[keep_sample]=n
          n=n+1
          # print(d)
          # print(mean)
          keep_sample=names(d)
          marker_modules_non[[marker_modules_non_length]]=names(d)
          marker_modules_non_length=marker_modules_non_length+1
          keep_k[[k]]=keep_sample
          #print(mean)
        }
      }
    }  
    
    #t=cutree(clust, k = cut_value)
    cut_value=cut_value+1
  }
  
  keep_k[sapply(keep_k, is.null)] = NULL
  
  ####################################

  #list(Stat_all = Stat_all, module_keep = module_keep, proportion = proportion)
  # proportion_matrix=proportion[[1]]
  # for (i in 2:length(proportion)) {
  #   proportion_matrix=rbind(proportion_matrix,proportion[[i]])
  # }
  # proportion_matrix=t(proportion_matrix)
  
  #E-Score
  e_mat <- SSMD_cal_escore(sig_matrix, Prop, data11)
  #list(predict_p = proportion_matrix,sig_gene_list = module_keep_plain)
  return(list(Proportion=Prop, marker_gene=module_keep_plain,Escore=e_mat,potential_modules=keep_k))
}
