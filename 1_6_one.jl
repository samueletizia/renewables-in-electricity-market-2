using Gurobi,JuMP
using Plots, Random, Printf, XLSX, CSV, DataFrames, Distributions

# SETS and DATA

SCENARIOS_TOT = String[]
for i in 1:600
    push!(SCENARIOS_TOT, "S" * string(i))
end


TIME_SLOT = String[]
for i in 1:24
    if i<=9
    push!(TIME_SLOT, "0" * string(i-1) * " - 0" * string(i))
    elseif i==10
        push!(TIME_SLOT, "09 - "* string(i))
    else
    push!(TIME_SLOT, string(i-1) * " - " * string(i))
    end
end


WIND_SCENARIO=["1","2","3","4","5","6","7","8","9","10"]


MARKET_PRICE_SCENARIO= ["MP1","MP2","MP3","MP4","MP5","MP6","MP7","MP8","MP9","MP10","MP11","MP12","MP13","MP14","MP15"]


T=length(TIME_SLOT)
WD=length(WIND_SCENARIO)
MP=length(MARKET_PRICE_SCENARIO)
DE=4 # deficit excess length
ST=length(SCENARIOS_TOT)

O=200
P=ST-O       # P = 600 - O

include("Day_ahead_price_forecast.jl")

# "price_forecast" is a 15x24 matrix - "wind_data" is a 10x24 - "deficit_excess" is a 4x24

scenarioss=zeros(T,3,ST)    #   all the scenarios

global iind=1

for i in 1:WD
    for j in 1:MP
        for k in 1:DE
            for t in 1:T
            scenarioss[t,:,iind] = [wind_data[i, t], price_forecast[j, t], deficit_excess[k, t]]  ###### WIND - PRICE - deficit
            end
            global iind += 1
        end
    end
end

s200=zeros(O)
scenarios_200=zeros(24,3,O)     

Random.seed!(14797)
s200 = sort(randperm(600)[1:O])

global xx=1

for oo in 1:O
    o=s200[oo]
    scenarios_200[:,:,xx]=scenarioss[:,:,o]
global xx=xx+1
end


wind_farm_CAP = 150 # MW

DA_wind=1
DA_price=2
sys=3                    # 1 if sys in excess (needs down regulation), 0 if it is in deficit (needs up regulation)
prob_in=1/O*ones(O)
prob_out=1/P*ones(P)

Balancing_price_in=zeros(T,O)

for o=1:O
    for t=1:T
        if scenarios_200[t,sys,o]==0
            Balancing_price_in[t,o]= 1.2*scenarios_200[t,DA_price,o]
        else
            Balancing_price_in[t,o]= 0.9*scenarios_200[t,DA_price,o]
        end
    end
end


# MODEL 

ONE_SIX= Model(Gurobi.Optimizer)


@variable(ONE_SIX, power_DA[1:T]>=0)

@variable(ONE_SIX, delta[1:T,1:O])           # if system is in excess (need down regulation), in every case it will pay 0.9*DA_price 
@variable(ONE_SIX, delta_more[1:T,1:O]>=0)   # no matter whether the balancing provided by the wind farm is helping the system or not
@variable(ONE_SIX,delta_less[1:T,1:O]>=0)    # 1.2 if the system is in deficit

@objective(ONE_SIX, Max, sum(prob_in[o]*(scenarios_200[t,DA_price,o]*power_DA[t] + Balancing_price_in[t,o]*delta[t,o]) for t=1:T, o=1:O))

@constraint(ONE_SIX,[t=1:T], power_DA[t]<=wind_farm_CAP)
@constraint(ONE_SIX, [t=1:T,o=1:O], delta[t,o] == scenarios_200[t,DA_wind,o] - power_DA[t])
#@constraint(ONE_SIX, [t=1:T,o=1:O], delta[t,o] == delta_more[t,o] - delta_less[t,o])

optimize!(ONE_SIX)



DA_POWER=zeros(T)
DELTA_IN=zeros(T,O)

for t=1:T
println(value(power_DA[t]))
DA_POWER[t]=value(power_DA[t])
end


for t=1:T
    for o=1:O
        DELTA_IN[t,o]=value(delta[t,o])
    end
end


profit_hourly_in=zeros(T,O)
profit_dayly_in=zeros(O)


    for o=1:O
        for t=1:T
        profit_hourly_in[t,o]= DA_POWER[t]*scenarios_200[t,DA_price,o] + Balancing_price_in[t,o]*DELTA_IN[t,o]
        end
    end

for o=1:O
    profit_dayly_in[o]=sum(profit_hourly_in[t,o] for t=1:T)
end

    for o=1:O
    println("Profit ",SCENARIOS_TOT[o],": ", @sprintf(" %.2f " , profit_dayly_in[o]) , " \$")
    end


total_profit_in=sum(profit_dayly_in[o] for o=1:O)


##############  OUT-SAMPLE PROFIT ###############

scenarios_400=zeros(24,3,P)
s400 = zeros(Int, ST-length(P))


global pp=1

for zz=1:ST
    if zz in s200  
    else
        s400[pp]=zz
        global pp=pp+1
end
end


global wp=1

for p in 1:P
    o=s400[p]
    scenarios_400[:,:,wp]=scenarioss[:,:,o]
global wp=wp+1
end


Balancing_price_out=zeros(T,P)

for p=1:P
    for t=1:T
        if scenarios_400[t,sys,p]==0
            Balancing_price_out[t,p]= 1.2*scenarioss[t,DA_price,p]
        else
            Balancing_price_out[t,p]= 0.9*scenarioss[t,DA_price,p]
        end
    end
end


DELTA_OUT=zeros(24,P)

for t=1:T
    for p=1:P
    DELTA_OUT[t,p] = scenarios_400[t,DA_wind,p] - DA_POWER[t]
    end
end



profit_hourly_out=zeros(T,P)
profit_dayly_out=zeros(P)


    for p=1:P
        for t=1:T
        profit_hourly_out[t,p]= DA_POWER[t]*scenarios_400[t,DA_price,p] + Balancing_price_out[t,p]*DELTA_OUT[t,p]
        end
    end

for p=1:P
    profit_dayly_out[p]=sum(profit_hourly_out[t,p] for t=1:T)
end

    for p=1:P
    println("Profit OUT ",SCENARIOS_TOT[p],": ", @sprintf(" %.2f " , profit_dayly_out[p]) , " \$")
    end
total_profit_out=sum(profit_dayly_out[p] for p=1:P)


println("\n")
println("IN-SAMPLE average profit: " , @sprintf(" %.2f " , total_profit_in*prob_in[1]) )

println("\n")
println("OUT-SAMPLE average profit: " , @sprintf(" %.2f " , total_profit_out*prob_out[1]) )