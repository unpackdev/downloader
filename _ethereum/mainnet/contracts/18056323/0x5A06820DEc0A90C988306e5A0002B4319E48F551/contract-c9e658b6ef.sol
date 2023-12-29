// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract Tether is ERC20, Ownable {
    constructor() ERC20("Tether", "USDT") {
        _mint(msg.sender, 5000000 * 10 ** decimals());
    }
}
