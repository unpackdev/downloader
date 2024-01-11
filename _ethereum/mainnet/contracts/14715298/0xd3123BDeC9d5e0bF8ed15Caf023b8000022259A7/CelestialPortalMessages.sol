// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

library CelestialPortalMessages {
	bytes32 constant RETRIEVE_FREAKS = keccak256("RETRIEVE_FREAKS");
	bytes32 constant RETRIEVE_CELESTIALS = keccak256("RETRIEVE_CELESTIALS");
	bytes32 constant RETRIEVE_FBX = keccak256("RETRIEVE_FBX");
	bytes32 constant RETRIEVE_ALL = keccak256("RETRIEVE_ALL");
}
