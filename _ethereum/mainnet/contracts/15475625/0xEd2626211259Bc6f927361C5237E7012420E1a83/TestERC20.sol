// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.14;

import "./ERC20.sol";

contract TestERC20 is ERC20 {
    uint8 private immutable _decimals;

    constructor(
        uint256 supply,
        string memory name,
        string memory symbol,
        uint8 decimals_
    ) ERC20(name, symbol) {
        _decimals = decimals_;
        _mint(msg.sender, supply);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
