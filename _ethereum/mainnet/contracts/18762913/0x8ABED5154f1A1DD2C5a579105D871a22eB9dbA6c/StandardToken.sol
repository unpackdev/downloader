// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.19;

import "./ERC20.sol";

contract StandardToken is ERC20 {
    uint8 _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals, uint256 totalSupply) ERC20(name, symbol) {
        _mint(_msgSender(), totalSupply);
        _decimals = decimals;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
