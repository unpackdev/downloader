// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./AntiSnipe.sol";

contract Derp is ERC20, AntiSnipe {
    constructor() ERC20("Derp", "DERP") {
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal view override {
        super._beforeTokenTransfer(from, to, amount, balanceOf(to));
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}