// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC20.sol";

contract DetailedERC20 is ERC20 {
    
    // add custom decimals
    uint8 private immutable _decimals;

    constructor(string memory _name, string memory _symbol, uint8 _underlyingDecimals) ERC20(_name, _symbol) {
        _decimals = _underlyingDecimals;
    }

   function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

}