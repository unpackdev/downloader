// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ClonesUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./AddressUpgradeable.sol";

import "./console.sol";

/**
 * @dev ERC1167 Minimal Proxy Factory
 */
contract ERC1167Factory is ContextUpgradeable {
    using AddressUpgradeable for address;

    event NewClone(address instance, address implementation, bytes32 salt);

    function clone(address implementation, bytes memory data) public returns (address instance) {
        instance = ClonesUpgradeable.clone(implementation);

        //data is optional
        if (data.length > 0) instance.functionCall(data, 'ERC1167Factory: Failed to call the proxy');

        emit NewClone(instance, implementation, bytes32(0));
    }

    function cloneDeterministic(
        address implementation,
        bytes32 salt,
        bytes memory data
    ) public returns (address instance) {
        //Salt init data
        salt = keccak256(abi.encodePacked(salt, _msgSender(), data));
        instance = ClonesUpgradeable.cloneDeterministic(implementation, salt);

        //data is optional
        if (data.length > 0) instance.functionCall(data, 'ERC1167Factory: Failed to call the proxy');

        emit NewClone(instance, implementation, salt);
    }

    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        bytes memory data
    ) public view returns (address predicted) {
        //Salt init data
        salt = keccak256(abi.encodePacked(salt, _msgSender(), data));
        predicted = ClonesUpgradeable.predictDeterministicAddress(implementation, salt);
    }
}
