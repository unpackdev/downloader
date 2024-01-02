// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./ERC20.sol";

contract ERC20Mock is ERC20 {
    uint8 private _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_,
        uint256 supply
    ) ERC20(name, symbol) {
        _decimals = decimals_;
        _mint(msg.sender, supply);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}
