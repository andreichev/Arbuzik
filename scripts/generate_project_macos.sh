#!/bin/bash

rm -rf xcode
mkdir xcode
cd xcode
cmake .. -G Xcode

open Arbuzik.xcodeproj