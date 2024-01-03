// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract MICKEY is ERC20 {
    address public owner;
    constructor() ERC20("MICKEY", "MICKEY") {
        _mint(msg.sender, 690_000_000_000 * 10 ** 18);
        owner = msg.sender;
    }
}