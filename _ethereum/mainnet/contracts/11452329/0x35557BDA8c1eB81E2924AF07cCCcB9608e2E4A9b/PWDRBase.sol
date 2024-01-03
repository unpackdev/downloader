// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// import "./ERC20.sol";

import "./PWDRToken.sol";
import "./PatrolBase.sol";

abstract contract PWDRBase is PatrolBase, PWDRToken {
    constructor(
        address addressRegistry,
        string memory name_, 
        string memory symbol_
    ) 
        public
        PWDRToken(name_, symbol_)
    {
        _setAddressRegistry(addressRegistry);
    }
}