// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract Balder is ERC20 {
    constructor() ERC20("Balder", "BLD") {
        _mint(msg.sender, 20000000 * 10 ** decimals());
    }
}