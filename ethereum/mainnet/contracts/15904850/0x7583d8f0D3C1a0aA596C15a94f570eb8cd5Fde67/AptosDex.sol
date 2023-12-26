// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "ERC20.sol";
import "Ownable.sol";

/*
    Aptos Dex
*/

contract AptosDex is ERC20, Ownable {

    constructor() ERC20("Aptos Dex", "APTDEX") {
        uint256 totalSupply = 500_000_000 * 1e18;
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        super._transfer(from, to, amount);
    }
}