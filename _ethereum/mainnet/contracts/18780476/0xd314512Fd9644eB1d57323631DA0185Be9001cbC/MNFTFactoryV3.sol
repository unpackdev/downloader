// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./Clones.sol";
import "./MNFTFactoryV3I.sol";

/// @notice Create a lore membership nft contract instance.
contract MNFTFactoryV3 is MNFTFactoryV3I {

    event FundingCollectionCreate(address instance);

    /// @notice The contract used as a master for cloning
    address public implementation;

    constructor(address _implementation){
        implementation = _implementation;
    }

    // @notice Create a clone of a contract and call an initializer function on it
    function createWithInitializer(bytes calldata callData) public returns (address){
        address instance = Clones.clone(address(implementation));
        emit FundingCollectionCreate(instance);
        callWithCalldata(instance, callData);
        return instance;
    }

    // @notice Create a deterministic clone of a contract and call an initializer function on it
    function createDeterministic(bytes32 salt, bytes calldata callData) public returns (address){
        address instance = Clones.cloneDeterministic(address(implementation), salt);
        emit FundingCollectionCreate(instance);
        callWithCalldata(instance, callData);
        return instance;
    }

    // @notice Predict the address of a deterministic clone before creating it
    function predictDeterministicAddress(bytes32 salt) public view returns (address){
        return Clones.predictDeterministicAddress(address(implementation), salt);
    }

    // @dev call a function on a contract with arbitrary calldata
    function callWithCalldata(
        address contractAddress,
        bytes calldata callData
    ) internal {
        (bool success,) = contractAddress.call{value: 0}(callData);
        require(success, "call failed");
    }
}
