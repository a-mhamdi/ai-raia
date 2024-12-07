##############################
#= DECISION TREE REGRESSION =#
##############################
# `versioninfo()` -> 1.11.1

using Markdown

md"Import librairies"
using CSV, DataFrames
using MLJ

md"Load data from CSV file"
df = CSV.read("../Datasets/50_Startups.csv", DataFrame)
schema(df)

md"Design the features"
X = df[!, 1:4]
colnames = ["rd", "admin", "spend", "state"]
rename!(X, Symbol.(colnames))
coerce!(X, :state => Multiclass)

md"Encoding the state column"
ce = ContinuousEncoder()
X = machine(ce, X) |> fit! |> MLJ.transform

md"Extract target vector"
y = df.Profit

md"Preparing for the split"
train, test = partition(eachindex(y), 0.8, shuffle=true, rng=123)
Xtrain, Xtest = X[train, :], X[test, :]
ytrain, ytest = y[train], y[test]

md"Load & instantiate the random forest regressor model"
RFR = @load RandomForestRegressor pkg=DecisionTree
rfr_ = RFR(max_depth=5, min_samples_split=3)

md"You may want to see [DecisionTree.jl](https://github.com/bensadeghi/DecisionTree.jl) and the unwrapped model type [`MLJDecisionTreeInterface.DecisionTree.RandomForestRegressor`](@ref)."

md"Train & fit"
rfr = machine(rfr_, Xtrain, ytrain) |> fit!
println("Params of fitted model are $(fitted_params(rfr).forest)")

md"Prediction"
yhat_rfr = predict(rfr, Xtest)

md"Results & metrics"
println("Error is $(sum((yhat_rfr .- ytest).^2) ./ length(ytest))")
