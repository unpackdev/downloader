/*
https://bankofjubjub.com/
https://github.com/bank-of-jubjub
https://twitter.com/bankofjubjub
*/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./ERC20.sol";
import "./Ownable.sol";

contract BankofJubJub is ERC20, Ownable {

    bool private launching;

    constructor() ERC20("Bank of JubJub", "Jub") Ownable(msg.sender) {

        uint256 _totalSupply = 100000000 * (10 ** decimals());

        launching = true;

        _mint(msg.sender, _totalSupply);
    }

    function enableSwapping() external onlyOwner{
        launching = false;
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {

        if(launching) {
            require(to == owner() || from == owner(), "Swapping is not yet actived");
        }

        super._update(from, to, amount);
    }
}