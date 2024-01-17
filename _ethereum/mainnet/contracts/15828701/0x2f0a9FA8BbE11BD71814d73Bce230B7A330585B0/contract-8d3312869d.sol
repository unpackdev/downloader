// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";

contract PUNKSINU is ERC20 {
    constructor() ERC20("PUNKS INU", "PIN") {
        _mint(msg.sender, 200000000 * 10 ** decimals());
    }
}
