// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract DroobyBucks is ERC20, ERC20Burnable {
    constructor() ERC20("DroobyBucks", "MDB") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}