#!/bin/bash
echo "clearing files to rebuild"
rm circuit.json
rm proving_key.json
rm proving_key.bin
rm verification_key.json
rm proof.json
rm public.json
rm verifier.sol
rm witness.json
rm witness.bin
# Compile the circuit circuit
# Not using c for my device
circom circuit.circom --r1cs --wasm --sym

# Compute the witness using WebAssembly
cd circuit_js
node generate_witness.js

cd ..
node circuit_js/generate_witness.js circuit_js/circuit.wasm input.json witness.wtns



# Start a new Powers of Tau ceremony
snarkjs powersoftau new bn128 15 pot12_0000.ptau -v

# Contribute to the ceremony
snarkjs powersoftau contribute pot12_0000.ptau pot12_0001.ptau --name="First contribution" -v -e="randomText"

# Phase 2
# Start the generation of phase 2
snarkjs powersoftau prepare phase2 pot12_0001.ptau pot12_final.ptau -v

# Generate a .zkey file that will contain the proving and verification keys together with all phase 2 contributions
snarkjs groth16 setup circuit.r1cs pot12_final.ptau circuit_0000.zkey

# Contribute to the phase 2 ceremony
snarkjs zkey contribute circuit_0000.zkey circuit_0001.zkey --name="1st Contributor Name" -v -e="randomText"

# Export the verification key
snarkjs zkey export verificationkey circuit_0001.zkey verification_key.json


# Generate proof
snarkjs groth16 prove circuit_0001.zkey witness.wtns proof.json public.json

# Verify proof
snarkjs groth16 verify verification_key.json public.json proof.json

# Generate argument calls for the Solidity contract
echo " "
echo " "
echo "Arguments for the Solidity contract"

snarkjs zkey export soliditycalldata public.json proof.json