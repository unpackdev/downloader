// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract RFDAOXCoin is ERC20, Ownable {
    constructor() ERC20("RFDAOX Coin", "RFDAOX") {
        _mint(msg.sender, 999800000 * 10 ** decimals());
    }
}
