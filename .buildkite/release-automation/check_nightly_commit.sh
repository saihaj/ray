#!/bin/bash

set -euo pipefail

# Check arguments
if [[ $# -ne 1 ]]; then
    echo "Missing argument to specify Ray image type."
    echo "Use: ray or ray-ml"
    exit 42
fi

RAY_TYPE=$1

pull_image() {
    TAG=$1
    echo "Pulling rayproject/$RAY_TYPE:$TAG"
    docker pull rayproject/"$RAY_TYPE":"$TAG"
}

get_image_ray_commit() {
    TAG=$1
    docker run -i --rm rayproject/"$RAY_TYPE":"$TAG" bash -c "python -u -c 'import ray; print(ray.__commit__)'" | grep '^[a-f0-9]\{40\}$'
}

verify_image_commit() {
    TAG=$1
    echo "Verifying Ray commit in $RAY_TYPE:$TAG"
    pull_image "$TAG"

    RAY_COMMIT=$(get_image_ray_commit "$TAG")
    if [[ "$RAY_COMMIT" != "$BUILDKITE_COMMIT" ]]; then
        echo "Ray commit hash is not correct in $RAY_TYPE:$TAG image"
        echo "Expected: $BUILDKITE_COMMIT"
        echo "Actual: $RAY_COMMIT"
        exit 42
    fi
    echo "Ray commit hash is correct in $RAY_TYPE:$TAG"
}

check_images() {
    VERSIONS=("cpu" "gpu" "cu118" "py39" "py39-cpu" "py39-gpu" "py39-cu118" "py310" "py310-gpu" "py310-cu118" "py310-cpu")
    TAGS=("nightly")

    for VERSION in "${VERSIONS[@]}"; do
        TAGS+=("nightly-$VERSION")
    done

    for TAG in "${TAGS[@]}"; do
        verify_image_commit "$TAG"
    done
}

check_images