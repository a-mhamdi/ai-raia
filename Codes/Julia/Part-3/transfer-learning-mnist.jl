# NOT WORKING YET

#######################################
#= Transfer Learning (MNIST DATASET) =#
#######################################
# Gray Color Images , i.e., n° of channnels = 1

using Markdown

using Metalhead
md"Load the pre-trained model"
md"[API Reference](https://fluxml.ai/Metalhead.jl/dev/api/reference/#API-Reference)"
vgg = VGG(16; pretrain=true).layers;

using DataAugmentation
tfm = CenterCrop((224, 224)) |> ImageToTensor()

using Flux
using Flux: onecold, onehotbatch

model = Chain(
    vgg[1:end-1],
    vgg[end][1:end-1],
    # Replace the last layer
    Dense(4096, 256),
    Dense(256, 10)
)

using MLDatasets
md"Load the MNIST dataset"
function get_data(split)
    data = MNIST(split)
    imgs, y = data.features ./ 255, onehotbatch(data.targets, 0:9);
    X = []
    for i in 1:length(y)
        img = apply(tfm, Image(RGB.(imgs[:,:,i]))) |> itemdata
        push!(X, img)
    end
    loader = Flux.Data.DataLoader((X, y); batchsize=64, shuffle=true);
    return loader
end

using Images
train_loader = get_data(:train);
test_loader = get_data(:test);

# Define a loss function and an optimizer
loss_fn = Flux.logitcrossentropy
opt_state = Flux.setup(Adam(3e-3), model[end]) # Freeze the weights of the pre-trained layers

using ProgressMeter
epochs = 3
# Fine-tune the model
for epoch in 1:epochs
    @showprogress for (X, y) in train_loader
        # Compute the gradient of the loss with respect to the model's parameters
        loss, ∇ = Flux.withgradient(model) do m
            ŷ = m(X)
            loss_fn(ŷ, y)
        end
        # Update the model's parameters using the optimizer
        Flux.update!(opt_state, model, ∇[1])
    end
    @info "Calculate the accuracy on the test set"
    for (X, y) in test_loader
        accuracy = sum(onecold(model(X)) .== onecold(y)) / length(y)
        println("Epoch: $epoch, Accuracy: $accuracy")
    end
end
