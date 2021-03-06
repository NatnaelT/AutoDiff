# Linear Regression with L1 penalty
PlotResults=false

useproc("GPU") # GPU is significantly faster for larger systems
#useproc("CPU")

StartCode()
X=ADnode()
w=ADvariable()
Y=ADnode()
loss=meanSquareLoss(X*w,Y) # mixed regularisation term
net=EndCode() # defines the graph

# instantiate parameter nodes and inputs:

D=100 # dimension of weight vector
N=100 # number of datapoints
truew=randn(D,1).*(rand(D,1).>0.8)
net.value[w]=truew
net.value[X]=randn(N,D)
net.value[Y]=net.value[X]*net.value[w] # make a realisable problem
net.value[w]=randn(D,1) # start with a random w

net=compile(net) # compile and preallocate memory

@gpu CUDArt.init([0]) # let the user do device management

@gpu net=convert(net,PROC,Float32)
#@gpu net=convert(net,PROC,Float64)


if 1==1

gradcheck(net)

# Training:
    tic()
println("Training: using $(net.gpu==true? "GPU" : "CPU") ")
ParsToUpdate=Parameters(net)
nupdates=500
LearningRate=0.01
error=Array(Float64,0)
velo=NesterovInit(net) # Nesterov velocity
for i=1:nupdates
    ADforward!(net)
    ADbackward!(net)
    push!(error,extract(net.value[net.FunctionNode])[1])
    printover("iteration $i: training loss = $(error[i])")
    for par in ParsToUpdate
        #GradientDescentUpdate!(net.value[par],net.gradient[par],LearningRate)
        NesterovGradientDescentUpdate!(net.value[par],net.gradient[par],velo[par],LearningRate,i)
    end
end
@gpu CUDArt.device_synchronize()
println()
    toc()
    
#println("\ntrue weights   ",round(100*truew')/100)
#println("learned weights",round(100*extract(net.value[w])')/100)

if PlotResults
    figure(1);plot(truew);title("true weights")
    figure(2);plot(extract(net.value[w])); title("learned weights")
end




end
