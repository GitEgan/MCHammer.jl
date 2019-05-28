#SIMULATION RESULTS AND CHARTS FOR MC HAMMER
#by Eric Torkia, April 2019

"""
MCH_Charts contains standard simulation charts for sensitivity, density, trends (time series with confidence bands) for simulation arrays generated by mc_hammer.
"""


# Density Chart
"""
    density_chrt(Data, x_label="Sim. Values")

Data is your array, either simulated or historical.
x_label [optional] allows you to customize your X axis label.
"""
function density_chrt(Data, x_label="Sim. Values")
      if x_label ==""
            x_label="x"
      end
chart = plot(Data, x=Data, Guide.xlabel(x_label), Guide.ylabel("Frequency"), Geom.density)
describe(Data)
println("")
print("Mean: ", mean(Data),"\n")
print("Std.Dev: ", std(Data),"\n")
print("Prob. of Neg.: ", GetCertainty(Data,0,0),"\n")
println("")
print("p10, p50, p90 : ", quantile(collect(Float64, Data),[0.1,0.5,0.9]),"\n")
return chart
end

# Histogram Chart
"""
    histogram_chrt(Data, x_label="Sim. Values")

Data is your array, either simulated or historical.
x_label [optional] allows you to customize your X axis label.
"""
function histogram_chrt(Data, x_label="Sim. Values")
      if x_label ==""
            x_label="x"
      end
chart = plot(Data, x=Data, Guide.xlabel(x_label), Guide.ylabel("Frequency"), Geom.histogram)
describe(Data)
println("")
print("Mean: ", mean(Data),"\n")
print("Std.Dev: ", std(Data),"\n")
print("Prob. of Neg.: ", GetCertainty(Data,0,0),"\n")
println("")
print("p10, p50, p90 : ", quantile(collect(Float64, Data),[0.1,0.5,0.9]),"\n")
return chart
end


#SENSITIVITY CHART
"""
    sensitivity_chrt(ArrayName, TargetCol, Chrt_Type=1)

**TargetCol**: used to select the output against which the other variables are analyzed for influence.

**Chrt_Type**: allows to change the chart metric: Spearman (1), PPMC (2) and  Contribution to Variance % (3)
"""
function sensitivity_chrt(ArrayName, TargetCol, Chrt_Type=1)
      #Chrt_Type =="" || "please select a chart"
      # if TargetCol == nothing
      #       error("please select your target output")
      # end
      # if Chrt_Type == nothing
      #       Chrt_Type = 3
      # end
M_Size = size(ArrayName,2)
ArrayName = DataFrame(ArrayName)

#Calculate Spearman
cor_mat_s = []
for i=TargetCol
cor_vector = []
      for i2=1:M_Size
       cor_i = cor(tiedrank(ArrayName[i]),tiedrank(ArrayName[i2]));
       push!(cor_vector,cor_i)
       #print(cov_i)
      end
 push!(cor_mat_s,cor_vector)
end
correl_vals_s = hcat(cor_mat_s...)

#Calculate PPMC
cor_mat_p = []
for i=TargetCol
cor_vector = []
      for i2=1:M_Size
       cor_i = cor(ArrayName[i], ArrayName[i2]);
       push!(cor_vector,cor_i)
      end
push!(cor_mat_p,cor_vector)
end
correl_vals_p = hcat(cor_mat_p...)

#This removes all entries of 1 (self)
#correl_vals = correl_vals[(correl_vals[:].!=1)]

ystr = names(ArrayName)
if Chrt_Type == 1
      color_code = correl_vals_s .<0
elseif Chrt_Type == 2
      color_code = correl_vals_p .<0
elseif Chrt_Type == 3
      color_code = correl_vals_s .<0
else
      Chrt_Type = 3
      color_code = correl_vals_s .<0
end

impact=[]

for i in 1:size(correl_vals_s,1)
      if color_code[i] == true
            value="Negative"
      else
            value="Positive"
      end
      push!(impact, value)
end

var_sign=[]
for i in 1:size(correl_vals_s,1)
      if color_code[i] == true
            value = -1
      else
            value = 1
      end
      push!(var_sign, value)
end

#Contribution to Variance
cont_var = correl_vals_s .^2
cont_var = cont_var ./ (sum(cont_var)-1)
cont_var = cont_var .* var_sign


graph_tbl = DataFrame(hcat(ystr,correl_vals_s, abs.(correl_vals_s), correl_vals_p, cont_var, impact))
names!(graph_tbl, [:name, :correlation, :abs_cor, :PPMC, :cont_var, :impact])


#This removes all entries of 1 (self) in DataTable
graph_tbl = graph_tbl[graph_tbl[:correlation].!=1,:]

#Sort
graph_tbl = sort(graph_tbl,3,rev=false)

println(graph_tbl)

if Chrt_Type ==1
      return plot(graph_tbl, y=:name, x=:correlation, Guide.Title("Variables with Biggest Impact"), Guide.xlabel("Rank Correlation"), Guide.ylabel("Input"), Geom.bar(orientation=:horizontal), Theme(bar_spacing=10pt), color=:impact, Scale.color_discrete_manual(colorant"red", colorant"deep sky blue"), Scale.x_continuous(minvalue=-1, maxvalue=1))
elseif Chrt_Type ==2
      return plot(graph_tbl, y=:name, x=:PPMC, Guide.Title("Variables with Biggest Impact"), Guide.xlabel("Pearson Correlation"), Guide.ylabel("Input"), Geom.bar(orientation=:horizontal), Theme(bar_spacing=10pt), color=:impact, Scale.color_discrete_manual(colorant"red", colorant"deep sky blue"), Scale.x_continuous(minvalue=-1, maxvalue=1))
elseif Chrt_Type ==3
      return plot(graph_tbl, y=:name, x=:cont_var, Guide.Title("Variables with Biggest Impact"), Guide.xlabel("% Contribution to Variance"), Guide.ylabel("Input"), Geom.bar(orientation=:horizontal), Theme(bar_spacing=10pt), color=:impact, Scale.color_discrete_manual(colorant"red", colorant"deep sky blue"),Scale.x_continuous(minvalue=-1, maxvalue=1))
else
      return plot(graph_tbl, y=:name, x=:cont_var, Guide.Title("Variables with Biggest Impact"), Guide.xlabel("% Contribution to Variance"), Guide.ylabel("Input"), Geom.bar(orientation=:horizontal), Theme(bar_spacing=10pt), color=:impact, Scale.color_discrete_manual(colorant"red", colorant"deep sky blue"), Scale.x_continuous(minvalue=-1, maxvalue=1))

end
end



#TREND CHART
"""
    trend_chrt(SimTimeArray, PeriodRange, quantiles=[0.05,0.5,0.95])

**trend_chrt** allows the visualization of a simulated time series. These can be generated using the GBMM function.

**PeriodRange** must constructed using the `Dates` package and use the following syntax :

      dr = collect(Date(2019,1,01):Dates.Year(1):Date(2023,01,01))
"""
function trend_chrt(SimTimeArray, PeriodRange, quantiles=[0.05,0.5,0.95])
#In order to stack vector entries, use the mapping function ****
AC_DF = vcat(map(x->x',SimTimeArray)...)
AC_DF = DataFrame(AC_DF)

trend_chart = []

for i = 1:size(AC_DF,2)
    push!(trend_chart, quantile!(AC_DF[i], quantiles))
end

#this allows us to join arrays generated by the quantile function
trend_chart = vcat(map(x->x',trend_chart)...)

#convert to time array to join dates and reconvert to DataFrame
trend_chart = TimeArray(PeriodRange, trend_chart)
trend_chart = DataFrame(trend_chart)

#Build Charts
names!(trend_chart, [:timestamp, :LowerBound, :p50, :UpperBound])
return plot(stack(trend_chart), y=:value, x=:timestamp, color=:variable, Geom.line)

end




#



#ADD Error Bar Example

# x = sort(rand(10)); xmin = 0.9x; xmax = 1.1x;
# ystr = map(i -> string(i) * " as a string", 1:10)
# plot(y = ystr, x = ex, xmin = xmin, xmax = xmax, Geom.errorbar)
