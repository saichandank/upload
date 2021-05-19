# The path to the Glow build folder.
GLOW_BUILD_PATH?=/home/osboxes/Desktop/Shared/glow_upstream/build_Debug

# The path to the image-classifier executable from the Glow build folder.
PROFILER=${GLOW_BUILD_PATH}/bin/image-classifier
COMPILER=${GLOW_BUILD_PATH}/bin/model-compiler

# Input name of the model.
PROFILER_MODEL=-model=model/mobilenet_v1_1.0_224.onnx -model-input-name=input
COMPILER_MODEL=-model=model/mobilenet_v1_1.0_224.onnx -network-name=model

# Image properties
IMAGE_PROPS=-image-mode=neg1to1 -image-layout=NHWC -image-channel-order=RGB

# Quantization schema
QUANT_PROPS=-quantization-schema=symmetric_with_power2_scale

# Profile model.
profile:
	${PROFILER} ./images/*.png ${PROFILER_MODEL} ${IMAGE_PROPS} -minibatch=1 -dump-profile=profile.yml -dump-graph-DAG=graph_profile.dot
	dot -Tpdf graph_profile.dot -o graph_profile.pdf

# Compile model.
compile: profile
	${COMPILER} -backend=CPU -emit-bundle=bundle ${COMPILER_MODEL} ${QUANT_PROPS} -load-profile=profile.yml -dump-graph-DAG=graph_compile.dot
	dot -Tpdf graph_compile.dot -o graph_compile.pdf

clean:
	rm -rf ./bundle
	rm -f profile.yml
	rm -f *.dot
	rm -f *.pdf
