// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract iToken is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("iToken", "ITCO") {
        _mint(address(0x6DbC7634dEee8d09c82D2984b3739BEB264EBA61), 1000000000 * 10 ** decimals());
    }
}