// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Erc20 is ERC20 {
    constructor() ERC20("Minterest Token", "MNT") {
        _mint(msg.sender, 100_000_030 ether);
    }
}