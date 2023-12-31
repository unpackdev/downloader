// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./Clones.sol";
import "./Create2.sol";
import "./ICloneable.sol";
import "./Helper.sol";

error InvalidVersion();
error InitializationFailed();
error AlreadyDeployed();
error VersionsImplementationAddressesNotMatch();

contract CNFTFactory is CommonAccess {
    using Clones for address;

    mapping(bytes32 => address) internal implementations;

    event ContractDeployed(bytes32 indexed version, address indexed contractAddress);

    constructor(bytes32[] memory versions, address[] memory implementationAddresses) {
        if (versions.length != implementationAddresses.length) {
            revert VersionsImplementationAddressesNotMatch();
        }
        for (uint256 i = 0; i < versions.length; i++) {
            implementations[versions[i]] = implementationAddresses[i];
        }
    }

    function deploy(bytes32 version, bytes32 salt, bytes calldata initCall) public returns (address) {
        address clone = getImplementation(version).cloneDeterministic(salt);

        emit ContractDeployed(version, clone);

        bytes memory returnData;
        bool success;
        (success, returnData) = clone.call(initCall);

        if (!success || ICloneable(clone).isInitialized() == false) {
            revert InitializationFailed();
        }

        return clone;
    }

    function getImplementation(bytes32 version) public view returns (address) {
        address implementation = implementations[version];

        if (implementation == address(0)) {
            revert InvalidVersion();
        }

        return implementation;
    }

    function deployNewContractAndSetImplementation(bytes32 version, bytes memory bytecode) external adminOrOwnerOnly {
        if (implementations[version] != address(0)) {
            revert AlreadyDeployed();
        }
        address newDeployedContract = Create2.deploy(0, version, bytecode);
        emit ContractDeployed(version, newDeployedContract);
        setImplementation(version, newDeployedContract);
    }

    function setImplementation(bytes32 version, address implementation) public adminOrOwnerOnly {
        if (implementations[version] != address(0)) {
            revert AlreadyDeployed();
        }
        implementations[version] = implementation;
    }

    function predictAddress(bytes32 version, bytes32 salt) public view returns (address) {
        return predictAddress(getImplementation(version), salt);
    }

    function predictAddress(address implementation, bytes32 salt) public view returns (address) {
        return implementation.predictDeterministicAddress(salt);
    }
}
