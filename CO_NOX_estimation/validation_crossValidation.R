#### ---- Library ---- ####
library(boot)
ds = read.csv("dataset.csv")
ds_train = read.csv("ds_train.csv")
ds_test = read.csv("ds_test.csv")
attach(ds_train)
#### ---- Validation, Cross Validation ---- ####
# Dal file least_square abbiamo prodotto 4 modelli: fit_all, fit1, fit_poly, fit1.poly2, fit1.poly3
# I quali sono stati ottenuti da una prima analisi basata su intuizioni.
# Questi modelli sono stati valutati attraverso un Validation Set Approach al fine di stimare MSE di test
# I problemi del Validation Set approach sono: 1. Elevata Variabilit� del MSE test, 2. Riduzione del set di training
# Adesso si vuole utilizzare la tecniche k-fold Cross Validation al fine di mettere a confronto
# i 4 modelli di sopra. 
# A partire da tale confronto, in questo file si vuole dimostrare come l'utilizzo di una tecnica di valutazione come quella del Validation Set Approach
# pu� portare a stime estremamente variabili.
# La tecnica LOOCV non verr� utilizzata in quanto non ritenuta opportuna ai fini dell'analisi, poich� non contiene cos� pochi dati da
# giustificarne l'utilizzo.

##### ---- Variabilit� Validation Set Approach ---- #### 
# Al fine di verificare la variabilit� del Validation Set Approach, si metteranno a confronto gli MSE di test prodotti
# dalla relazione CO con TIT, a partire dalla relazione lineare fino ad arrivare al polinomio di grado 4.
set.seed(1)

val.err = matrix(data=NA,nrow=10,ncol=5)
train.err = matrix(data=NA, nrow = 10, ncol = 5)

n = nrow(ds)
training = (n*70)/100
  
for(i in 1:10){
  for(j in 1:5)  {
    set.seed(i)
    train = sample(1:n, training)
    lm_fit = lm(CO~poly(TIT, j), data = ds, subset = train)
    train.err[i, j] = mean((predict(lm_fit, newdata = ds[train, ]) - ds[train, "CO"])^2)
    val.err[i, j] = mean((predict(lm_fit, newdata = ds[-train, ]) - ds[-train, "CO"])^2)
  }
}

# Si osserva come effettivamente abbiamo un'elevata variabilit� della stima del MSE di test
dev.new()
plot(c(1:5), val.err[1,],type = "l", xlab = "polynomial degree", ylab = "test MSE", col = "red", ylim = range(min(val.err):max(val.err)), lwd = 3)
col = c("violet", "black", "orange", "yellow", "green", "black", "pink", "blue", "pink")
for(i in 2:10){
  for(j in 2:5){
    lines(c(1:5), val.err[i,], col = col[i], lwd = 3)
  }
}

dev.new()
plot(c(1:5), train.err[1,],type = "l", xlab = "polynomial degree", ylab = "train MSE", col = "red", ylim = range(min(val.err),max(val.err)), lwd = 3)
col = c("violet", "black", "orange", "yellow", "green", "black", "pink", "blue", "pink")
for(i in 2:10){
  for(j in 2:5){
    lines(c(1:5), train.err[i,], col = col[i], lwd = 3)
  }
}

#### ---- K-Fold Cross Validation ---- ####
set.seed(1)

kval.err = matrix(data=NA,nrow=10,ncol=5)

n = nrow(ds)

for(i in 1:10){
  for(j in 1:5)  {
    print(i)
    set.seed(i)
    glm_fit = glm(CO~poly(TIT, j), data = ds)
    kval.err[i, j] = cv.glm(ds, glm_fit, K = 10)$delta[1]
  }
}

# Si osserva effettivamente come la stima del MSE di test del k-fold CV � pi� stabile di quella del Validation Set Approach
# K-fold Cross Validation, risulta vincere il bias-variance trade-off, in quanto:
# Bias: minore del Validation Set, e maggiore del LOOCV
# Variance: maggiore del LOOCV (che risulta essere una procedura deterministica, genera un risultato che � una media di CV errors correlati tra loro)
# ma minore del Validation Set Approch.
dev.new()
plot(c(1:5), kval.err[1,],type = "l", xlab = "polynomial degree", ylab = "train MSE", col = "red", ylim = range(min(kval.err),max(kval.err)), lwd = 3)
col = c("violet", "black", "orange", "yellow", "green", "black", "pink", "blue", "pink")
for(i in 2:10){
  for(j in 2:5){
    lines(c(1:5), kval.err[i,], col = col[i], lwd = 3)
  }
}

#### ---- K-fold CV sui modelli generati ---- ####
# fit_all, fit1, fit_poly, fit1.poly2, fit1.poly3
# Si osserva che effettivamente l'introduzione della relazione non lineare 
# effettivamente comporta dei miglioramenti.
glm_fit_all = glm(formula = CO~., data = ds_train) 
fit_all_cv = cv.glm(ds_train, glm_fit_all, K = 10)$delta[1] #  2.244833
mean((predict(glm_fit_all, ds_test)-ds_test[,"CO"])^2) # 2.220337

glm_fit1 = glm(formula = CO~.-TEY-CDP-GTEP, data = ds_train) 
fit_1_cv = cv.glm(ds_train, glm_fit1, K = 10)$delta[1] # 2.281462

glm_fit_poly = glm(formula = CO~poly(TIT,2), data = ds_train) 
fit_poly_cv = cv.glm(ds_train, glm_fit_poly, K = 10)$delta[1] # 2.031061

glm_fit1_poly3 = glm(formula = CO~.-TEY-CDP-GTEP-TIT+poly(TIT, 3), data = ds_train) 
fit1_poly3_cv = cv.glm(ds_train, glm_fit1_poly3, K = 10)$delta[1] # 1.970951


