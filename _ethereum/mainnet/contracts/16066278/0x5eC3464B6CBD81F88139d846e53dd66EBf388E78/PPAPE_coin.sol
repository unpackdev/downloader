// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

/// @custom:security-contact ape@ppape.io
contract PPAPECoin is ERC20, Ownable {
    constructor() ERC20("PPAPECoin", "PPAPE") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}
