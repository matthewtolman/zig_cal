#!/usr/bin/env bash
echo "Fetching master"
zigup fetch master
echo "Fetching 0.13.0"
zigup fetch 0.13.0

zigup run master build test && \
	echo "Passed on nightly" \
zigup run 0.13.0 build test && \
	echo "Passed on stable 0.13.0"
