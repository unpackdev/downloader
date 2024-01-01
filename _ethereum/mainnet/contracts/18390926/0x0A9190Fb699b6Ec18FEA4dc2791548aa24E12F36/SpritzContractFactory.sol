// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import "./Create2.sol";

/**
 * @title SpritzContractFactory
 * @dev This contract acts as a factory for deploying spritz contract instances using CREATE2.
 */
contract SpritzContractFactory {
    using Create2 for bytes32;

    error InvalidSalt();

    /**
     * @dev Modifier to ensure that the first 20 bytes of a submitted salt match
     * those of the calling account. This provides protection against the salt
     * being stolen by frontrunners or other attackers.
     * @param salt bytes32 The salt value to check against the calling address.
     */
    modifier containsCaller(bytes32 salt) {
        if (address(bytes20(salt)) != msg.sender) {
            revert InvalidSalt();
        }
        _;
    }

    /**
     * @dev Deploy a new contract instance using CREATE2.
     * @param salt The nonce that will be passed into the CREATE2 call.
     * @param contractBytecode The contract initialization code
     */
    function deploy(bytes32 salt, bytes calldata contractBytecode) external payable containsCaller(salt) {
        Create2.deploy(0, salt, contractBytecode);
    }

    /**
     * @dev Compute the address of a contract that would be deployed using a specific accountReference.
     * @param salt The reference for the account (usually bytes32).
     * @param contractBytecode The reference for the account (usually bytes32).
     * @return computedAddress The computed address of the contract.
     */
    function computeAddress(
        bytes32 salt,
        bytes calldata contractBytecode
    ) external view returns (address computedAddress) {
        uint256 existingContractSize;

        computedAddress = Create2.computeAddress(salt, keccak256(contractBytecode));

        assembly {
            existingContractSize := extcodesize(computedAddress)
        }

        if (existingContractSize > 0) {
            return address(0);
        }
    }
}
