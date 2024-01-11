//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title KeysManager interface
/// @author Ankit Parashar
interface IKeysManager {

    enum State { INVALID, VALID, ACTIVATED, DEPOSITED }

    struct Validator {
        State state;
        bytes signature;
        address nodeOperator;
        bytes32 deposit_root;
    }

    function validators(bytes calldata publicKey) external view returns (Validator memory);

    function addValidator(bytes calldata publicKey, bytes calldata signature,  address nodeOperator) external;

    function activateValidator(bytes[] memory publicKey) external;

    function depositValidator(bytes memory publicKey) external;

    function nodeOperatorValidatorCount(address usr) external returns (uint256);
}