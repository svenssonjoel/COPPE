# COPPE



## Questions

  - Tensor dimensionality is not a hyperparameter?
   `batch_normalize: tensor([h, w, c]) -> tensor([h, w, c])`
    - The dimensionality is usually inferred from the input, the type (e.g. `conv`) of the layer and the hyperparameters (e.g. `stride`, `kernel_size` and `padding`). The dimensionality itself is not considered a hyperparameter.

  - Are there a fixed set of possible hyperparameters?
    - Depends on what do you mean by fixed. For each layer type, the set of possible hyperparameters are different. But you can assume that for a given type, the set is fixed.

  - I guess some hyperparameters are only applicable to some kinds of layers?
    Does it make sense to have types of hyperparameters specifically
    for one kind of layer?
    so conv would have CONV_Hyperparameters
       batch-normalize would have BN_Hyperparameters
       and so on?
    Maybe it is ok if there is only HyperParameters and you can
    select which to set or not for each layer?
    - Yes absolutely makes sense to have that. We can also have a set of all possible hyperparameters and draw a subset from this pool for each specific layer type. The benefit would be to have a unified abstraction for all hyperparameters. If you think it also makes sense from an implementation point of view, I can come up with an abstraction that we can experiment with.

  - Excerpt from example below:
  ```
   - type:    <- This is a layer of type conv?
      conv
    hyperparams: <- with these Hyperparameters
      strides:
        - 1
        - 1
      filters:
        16
  - type: batch_normalize <- this is a new layer (that gets input from above)?
    name: conv <- what is this? why is the BN layer named conv
  ```
    - This is a layer of type conv? Yes
    - This is a new layer (that gets input from above)? Yes
    - What is this? why is the BN layer named conv? It is the name for the output of the batch norm layer. It is arbitrarily chosen. I called it conv because the batch_norm layer is a post-processing function so I just ignored it and called the output conv (coz conv here performs the main functionality). But the naming is arbitrary here.



## Information
Note:
- I use `tensor(dimension)` to denote the shape, where dimension is a list without batch size.
- Example APIs can be found in https://pytorch.org/docs/stable/nn.html.

Examples:
1. `batch_normalize`: batch normalization layer
- Description: normalize the features so their values don't blow up (https://en.wikipedia.org/wiki/Batch_normalization)
- Example API: `torch.nn.BatchNorm2d(num_features, eps=1e-05, momentum=0.1, affine=True, track_running_stats=True)`
- `batch_normalize.yml`:
```
variance_epsilon: # there are other hyperparameters but they won't have effects on the implementation
  0.001
```
- Dimensionality: `batch_normalize: tensor([h, w, c]) -> tensor([h, w, c])`

2. `conv`: 2d convolutional layer
- Description: doing 2d convolutions, which will change the dimensions between inputs and outputs
- Example API: `torch.nn.Conv2d(in_channels, out_channels, kernel_size, stride=1, padding=0, dilation=1, groups=1, bias=True, padding_mode='zeros')`
- `conv.yml`:
```
padding:
  SAME # zero padding p=k-1
strides: # list of strides on height and width [s_h, s_w]
  - 2 # the skips for the sliding window
  - 2
initialization:
  random
filters: # number of output channels f
  64
kernel_size:
  - 3 # size of the kernels [k_h, k_w]
  - 3
```
- Dimensionality: `conv: tensor([h, w, c]) -> tensor([(h-k_h+2p)/s_h+1, (w-k_w+2p)/s_w+1, f])`

Another useful one is `add`, where basically we have to make sure that we are summing up tensors with the same shape. Relu is a piecewise linear function. There's no hyperparameter and it doesn't change the size so we can skip that one for now since it's trivial.
Please let me know if things are unclear!



## YAML Format

```
params_network:
  - type:
      conv
    hyperparams:
      strides:
        - 1
        - 1
      filters:
        16
  - type: batch_normalize
  - type: relu

  - type:
      conv
    hyperparams:
      strides:
        - 1
        - 1
      filters:
        16
  - type: batch_normalize
    name: conv

  - type: add
    input_layer:
      - input_layer
      - conv
  - type: relu
```


## Ordering and other properties.


- Ordering common-sense rules or guidelines

  - Never use patterns 
    - No two relus directly after eachother
    - No batchnorm relu batchnorm relu ... sequences
   

  - Block is defined as, one meaningful layer.
    Sequence of layers containing one meaningful layer.
    - Within block and between block properties. 

  - Meaningful layers (Makes structural difference)
    - conv 

## Concatenation

conat a b

dim(a) = [X,Y,p]
dim(b) = [Z,W,q]

X == Z
Y == W

dim(output) = [X,Y,p+q]


## Downsampling

downsample(a)

paramerters:
- Function: Average, Max, 
- Hyperparameters: Stride 


## Upsampling