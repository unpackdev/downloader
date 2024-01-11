// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./ERC20.sol";

abstract contract ERC20Decimals is ERC20 {
    uint8 private immutable _decimals;

    constructor(uint8 decimals_) {
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}

contract HOPE is ERC20Decimals {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialBalance_
    ) ERC20(name_, symbol_) ERC20Decimals(decimals_) {
        require(initialBalance_ > 0, "HOPE: supply cannot be zero");

        _mint(_msgSender(), initialBalance_);
    }

    function decimals() public view virtual override returns (uint8) {
        return super.decimals();
    }
}