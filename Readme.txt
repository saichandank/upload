Problem:
- This problem arises when trying to quantize a MobileNetV1 model
- Our backend opts to lower the last Conv2D layer into a FullyConnected.
- Doing this the layer does NOT get quantized.

Steps to reproduce the problem:
1. We will use the CPU backend to reproduce the problem.
   Replace the CPUBackend::shouldLower() function with the following code
   which chooses to lower the Conv2D 1x1 (last layer from the model) into a FC.

bool CPUBackend::shouldLower(const Node *N) const {
  switch (N->getKind()) {
  case Kinded::Kind::ReluNodeKind:
  case Kinded::Kind::ClipNodeKind:
  case Kinded::Kind::LeakyReluNodeKind:
  case Kinded::Kind::SparseLengthsSumNodeKind:
    return false;
  case Kinded::Kind::ConvolutionNodeKind: {
    auto *convNode = llvm::dyn_cast<ConvolutionNode>(N);
    ShapeNHWC inpShape = ShapeNHWC(convNode->getInput().dims());
    ShapeNHWC outShape = ShapeNHWC(convNode->getResult().dims());
    if (isConvolutionSameAsFullyConnected(convNode) && inpShape.h == 1 && outShape.h == 1 && inpShape.w == 1 && outShape.w == 1) {
      return true;
    } else { 
      return false;
    }
  }
  default:
    return true;
  }
}

2. Replace the GLOW_BUILD_PATH variable from Makefile to your path.

3. Run the following command to profile, quantize and compile the model.
   make compile

When looking at the compiled graph I find floating-point MatMul + BatchedAdd for the last layer
whereas quantized ones should have been found.
