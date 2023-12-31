// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract SatoshiDragon is ERC20, Ownable {
    constructor() ERC20("Satoshi Dragon", "DRAGON") {
        _mint(msg.sender, 21000000 * 10 ** decimals());
    }
}
