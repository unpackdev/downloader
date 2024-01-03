// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./Ownable.sol";
import "./IRegistry.sol";

contract Registry is Ownable, IRegistry {
    mapping(address => bool) internal registry;

    function register(address handler) external onlyOwner returns (bool) {
        registry[handler] = true;
    }

    function deregister(address handler) external onlyOwner returns (bool) {
        registry[handler] = false;
    }

    function isValid(address handler)
        external
        view
        override
        returns (bool result)
    {
        return registry[handler];
    }
}
