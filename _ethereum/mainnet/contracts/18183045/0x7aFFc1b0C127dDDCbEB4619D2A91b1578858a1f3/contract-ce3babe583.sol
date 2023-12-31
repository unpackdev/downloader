// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract Memeolympics is ERC20 {
    constructor() ERC20("Memeolympics", "MOLY") {
        _mint(msg.sender, 10000000 * 10 ** decimals());
    }
}
