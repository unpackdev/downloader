// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20Burnable.sol";

import "./ERC677.sol";

contract CrunchToken is ERC677, ERC20Burnable {
    constructor() ERC20("Crunch Token", "CRUNCH") {
        _mint(msg.sender, 10765163 * 10**decimals());
    }
}
