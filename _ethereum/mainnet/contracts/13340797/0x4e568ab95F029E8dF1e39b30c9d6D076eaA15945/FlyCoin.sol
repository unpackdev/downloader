// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

//import "./ERC20.sol";
//import "./ERC20Burnable.sol";

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract FlyCoin is ERC20, ERC20Burnable {
    constructor() ERC20("FlyCoin", "FLY") {
        _mint(msg.sender, 100000000000 * 10 ** decimals()); // 18 decimal places, the default.
    }

}
