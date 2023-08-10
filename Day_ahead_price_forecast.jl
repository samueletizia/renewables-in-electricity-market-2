using Gurobi,JuMP
using Plots, Random, Printf, XLSX, CSV, DataFrames, Distributions

# Create a dataframe
Day_1 = [133.08, 125.46, 124.96, 127.66, 130.58, 141.35, 163.45, 186.03, 186.03, 152.90, 126.69, 118.47, 115.56, 114.12, 115.14, 119.86, 132.21, 162.74, 183.69, 178.10, 158.84, 142.27, 142.05, 131.51]
Day_2 = [125.82, 128.57, 130.03, 131.47, 130.01, 135.58, 164.99, 181.11, 177.62, 141.44, 124.36, 116.79, 115.39, 113.64, 117.69, 128.62, 152.64, 166.38, 184.91, 159.44, 152.08, 157.56, 144.91, 139.90]
Day_3 = [140.30, 130.18, 130.59, 128.43, 127.78, 135, 162.19, 187.03, 195.39, 166.48, 131.12, 123.01, 111.94, 103.61, 96.10, 24.57, 23.97, 24.75, 25.47, 86.94, 38.06, 23.17, 22.37, 21.56]
Day_4 = [24.81, 24.71, 86.91, 47.95, 25.56, 27.64, 29.70, 98.82, 100.69, 96.89, 73.94, 45.01, 40.92, 40.60, 44.94, 87.06, 106.90, 140, 151.66, 143.79, 122.99, 114.88, 112.53, 108.97]
Day_5 = [107.53, 106.25, 105.55, 106.84, 104.99, 105.81, 105.94, 108.39, 107.72, 107.73, 105.18, 106.80, 106.83, 105.14, 106.80, 111.55, 120.12, 145.14, 166.67, 170.14, 156.39, 149.86, 141.50, 125.48]
Day_6 = [134.50, 122.44, 120.30, 121.11, 122.41, 137.44, 159.80, 185, 217.09, 189.99, 170.26, 160.84, 149.92, 144.95, 144.30, 145.78, 152, 162.03, 184.87, 176.81, 149.99, 133.60, 120.65, 108.58]
Day_7 = [100.95, 94.26, 85, 78.96, 78.52, 85.57, 98.71, 99.57, 105.59, 98.45, 97.30, 94.26, 87.57, 93.86, 95.07, 97.60, 106.60, 123.40, 149.49, 129.23, 113.35, 112.39, 68.04, 57.42]
Day_8 = [73.61, 71.01, 70.07,83.32, 107.78, 118.23, 140.68, 158.53, 173.10, 163, 152.99, 144.17, 137.17, 135.10, 137.42, 141.08, 144.47, 153.01, 166.89, 170.02, 153.77, 134.64, 128.82, 119]
Day_9 = [113.66, 111.39, 111.02, 109.38, 111.22, 113.02, 137.94, 158.09, 164.14, 154.64, 142.36, 131.81, 122, 116.45, 116.19, 116.72, 118.36, 135.85, 147.22, 145.04, 135.10, 125.09, 123.82, 109.70]
Day_10 = [102.89, 100.68, 99.06, 98.84, 99.09, 105, 119.81, 136.91, 140.91, 136.61, 131.89, 125.10, 116.42, 112.84, 114.91, 112.62, 110.10, 129.34, 135.48, 133.92, 115.41, 108.96, 99.99, 85.49]
Day_11 = [70.22, 71.11, 73.08, 80.44, 85.76, 96.18, 104.24, 110.09, 111.27, 106.37, 93.81, 81.95, 78.66, 60, 60.96, 80.65, 98.02, 106.45, 114.53, 110.43, 106.03, 103.42, 101.19, 89.90]
Day_12 = [64.83, 59.94, 57.76, 56.43, 57.06, 57, 59.08, 65.07, 81.76, 81.72, 92, 87.79, 80.40, 68.96, 70, 74.90, 85.05, 100.91, 119.85, 117.69, 105.85, 101.44, 92.59, 65.02]
Day_13 = [49.84, 39.15, 34.57, 30.46, 33.70, 34.18, 38.49, 77.71, 79.81, 42.46, 31.26, 30.86, 33.28, 33.80, 32.59, 31.58, 31.66, 47.38, 52.48, 48.87, 43.84, 42.18, 34.60, 23.32]
Day_14 = [49.84, 39.15, 34.57, 30.46, 33.70, 34.18, 38.49, 77.71, 79.81, 42.46, 31.26, 30.86, 33.28, 33.80, 32.59, 31.58, 31.66, 47.38, 52.48, 48.87, 43.84, 42.18, 34.60, 23.32]
Day_15 = [59.83, 56.95, 56.94, 56.97, 54.97, 57.23, 112.86, 136.33, 148.68, 111.63, 103.27, 60.06, 53.13, 50.77, 60.02, 91.65, 101.05, 108.07, 111.23, 109.53, 105.26, 105.06, 81.67, 72.91]

# Create a matrix of the data 
price_forecast1 = [Day_1, Day_2, Day_3, Day_4, Day_5, Day_6, Day_7, Day_8, Day_9, Day_10, Day_11, Day_12, Day_13, Day_14, Day_15]
price_forecast=zeros(15,24)

for i=1:15
    price_forecast[i,:]=price_forecast1[i]
end
# Read in the data from the CSV file as a DataFrame



df = CSV.read("wind_power_1.csv", DataFrame, header=false)
wind_data = Matrix(df)


Random.seed!(1234)
deficit_excess=rand(0:1, 4, 24)




# p = 0.5
# dist = Bernoulli(p)
# exess_deficit1 = 2*rand(dist, 24).-1
# exess_deficit2 = 2*rand(dist, 24).-1
# exess_deficit3 = 2*rand(dist, 24).-1
# exess_deficit4 = 2*rand(dist, 24).-1
 
# print(exess_deficit1,'\n', exess_deficit2,'\n', exess_deficit3,'\n', exess_deficit4)

# # Create a list of 24 random values between 0 and 5, indincating the amount of deficit or excess in the balancing stage in every hour of the next day
 
# Max_deficit_excess = 5
# deficit_excess1 = Max_deficit_excess*rand(24)
# deficit_excess2 = Max_deficit_excess*rand(24)
# deficit_excess3 = Max_deficit_excess*rand(24)
# deficit_excess4 = Max_deficit_excess*rand(24)
 
# # Multiply the random values with the random binary variables to get the final values of the deficit or excess in the balancing stage in every hour of the next day
# deficit_excess1 = deficit_excess1.*exess_deficit1
# deficit_excess2 = deficit_excess2.*exess_deficit2
# deficit_excess3 = deficit_excess3.*exess_deficit3
# deficit_excess4 = deficit_excess4.*exess_deficit4
 
# deficit_excess=zeros(4,24)
# deficit_excess[1,:]=deficit_excess1
# deficit_excess[2,:]=deficit_excess2
# deficit_excess[3,:]=deficit_excess3
# deficit_excess[4,:]=deficit_excess4
