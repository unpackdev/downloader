// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./PatrolBase.sol";
import "./LodgeToken.sol";

abstract contract LodgeBase is PatrolBase, LodgeToken {
    constructor(
        address addressRegistry,
        string memory _newuri
    ) 
        internal 
        LodgeToken(_newuri)
    {
        _setAddressRegistry(addressRegistry);
    }
}