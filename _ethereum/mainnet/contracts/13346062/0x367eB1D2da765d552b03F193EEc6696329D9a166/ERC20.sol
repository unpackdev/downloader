// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20.sol";

contract ERC20Token is ERC20 {
    constructor(
        uint256 initialSupply,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}

contract ERC20TokenDec6 is ERC20 {
    constructor(
        uint256 initialSupply,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}
