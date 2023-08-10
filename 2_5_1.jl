using Gurobi,JuMP
using Plots, Random, Printf, XLSX, CSV, DataFrames, Distributions, MathOptInterface

# SETS and DATA

GEN_S=["S1","S2","S3","S4"]                  # price MAKER generators
GEN_O=["O1","O2","O3","O4"]                  # price TAKER generators
DEMAND=["D1","D2","D3","D4"]                 # demand
NODE=["N1","N2","N3","N4","N5","N6"]         # nodes
TIME_SLOT=["00-01","01-02","02-03","03-04","04-05","05-06","06-07","07-08","08-09","09-10","10-11","11-12","12-13","13-14","14-15","15-16","16-17","17-18","18-19","19-20","20-21","21-22","22-23","23-24"]

T=length(TIME_SLOT)
S=length(GEN_S)
O=length(GEN_O)
D=length(DEMAND)
N=length(NODE)

D_Location=[3 4 5 6]    # demand location
S_Location=[1 2 3 6]    # price MAKER generators locations
O_Location=[1 2 3 5]    # price TAKER generators locations

D_quantity=[200 400 300 250]         # MW
# D_bid_price=[26.5 24.7 23.1 22.5]    # euro/MWh
D_over_time =    [0.2 0.2 0.2 0.3 0.4 0.6 0.9 1.1 1.0 1.0 0.9 0.8 0.9 1.0 0.9 1.1 1.0 1.2 1.1 0.8 0.8 0.8 0.6 0.4]    # demand time variation
WIND_over_time = [0.6 0.7 1.0 1.0 1.3 1.1 0.9 0.8 0.9 0.6 0.7 0.8 0.6 1.0 0.8 0.8 0.9 0.9 0.8 0.7 0.6 0.5 0.3 0.3]    # wind time variation

D_bid_price_T=zeros(D,T)

for t=1:T
    Random.seed!(t)
    D_bid_price_T[:,t] = sort(rand(20:30,D),rev=true)  # bid price random array
end

D_quantity_T=zeros(D,T)
for t=1:T
  for d=1:D
    D_quantity_T[d,t]=D_quantity[d]*D_over_time[t]         ### the demand is not constant for each hour but varies during the day, making the price varying as well
  end
end

S_capacity=[155 100 155 197]     # MW
O_capacity=[0.75*450 350 210 80]      # MW
O_capacity_T=zeros(O,T)

for o=1:O
    for t=1:T
        if o==1
        O_capacity_T[o,t]= O_capacity[o]*WIND_over_time[t]
        else
            O_capacity_T[o,t]=O_capacity[o]
        end
    end
end


S_cost=[15.2 23.4 15.2 19.1]     # euro/MWh
O_cost=[0 5 20.1 24.7]           # euro/MWh

S_ramp=[90 85 90 120]    # MW/h
O_ramp=[0 350 170 80]    # MW/h

BB=50

TWO_FIVE_ONE= Model(Gurobi.Optimizer)

@variable(TWO_FIVE_ONE, S_prod[1:S,1:T])
@variable(TWO_FIVE_ONE, O_prod[1:O,1:T]>=0)
@variable(TWO_FIVE_ONE, theta[1:N,1:T])
@variable(TWO_FIVE_ONE, demand_elastic[1:D,1:T]>=0)

@constraint(TWO_FIVE_ONE, mu_up[s=1:S,t=1:T], S_prod[s,t]<=S_capacity[s])                  # capacity contraint
@constraint(TWO_FIVE_ONE, mu_down[s=1:S,t=1:T], S_prod[s,t]>=0) 
@constraint(TWO_FIVE_ONE, [o=1:O,t=1:T], O_prod[o,t]<=O_capacity_T[o,t])                       # capacity contraint
@constraint(TWO_FIVE_ONE,[t=1:T], theta[1,t]==0)                                          # theta of node 1 =0
@constraint(TWO_FIVE_ONE, [d=1:D,t=1:T], demand_elastic[d,t]<=D_quantity_T[d,t])
@constraint(TWO_FIVE_ONE, [s=1:S,t=2:T], S_prod[s,t] <= S_prod[s,t-1] + S_ramp[s])       # ramp up  constraint for MAKER
@constraint(TWO_FIVE_ONE, [s=1:S,t=2:T], S_prod[s,t-1] - S_ramp[s] <= S_prod[s,t])
@constraint(TWO_FIVE_ONE, [o=2:O,t=2:T], O_prod[o,t] <= O_prod[o,t-1] + O_ramp[o])       # ramp up constraint for TAKER
@constraint(TWO_FIVE_ONE, [o=2:O,t=2:T], O_prod[o,t-1] - O_ramp[o] <= O_prod[o,t])


@constraint(TWO_FIVE_ONE, lambda[n=1:N,t=1:T],
                                                  - sum(demand_elastic[d,t]*(D_Location[d]==n ? 1 : 0) for d=1:D)          # if the demand is located in the right node then it is taken into account otherwise not
                                                  + sum(S_prod[s,t]*(S_Location[s]==n ? 1 : 0) for s=1:S)              # same for the production S and O      
                                                  + sum(O_prod[o,t]*(O_Location[o]==n ? 1 : 0) for o=1:O)                 
                                                  - sum(BB*(theta[n,t]-theta[m,t]) for m=1:N) == 0)

@objective(TWO_FIVE_ONE,Max, sum(sum(D_bid_price_T[d,t]*demand_elastic[d,t] for d=1:D) - sum(S_cost[s]*S_prod[s,t] for s=1:S) - sum(O_cost[o]*O_prod[o,t] for o=1:O)  for t=1:T))

start_time = time()
optimize!(TWO_FIVE_ONE)
end_time = time()


################ VISUALIZATION ###################



println("MARKET PRICES: \n")

market_price=zeros(N,T)

for t=1:T
    n=1
    market_price[n,t]=value(dual.(lambda[n,t]))
    println("Market price at time ",TIME_SLOT[t], " : ", @sprintf("%.2f" , market_price[n,t]))
end

# Print number of variables and constraints
println("\n")
println("Number of variables: ", JuMP.num_variables(TWO_FIVE_ONE))
println("Number of constraints: ", JuMP.num_constraints(TWO_FIVE_ONE, count_variable_in_set_constraints=false))


# Print computational time
println("Computational time: ", end_time - start_time)
