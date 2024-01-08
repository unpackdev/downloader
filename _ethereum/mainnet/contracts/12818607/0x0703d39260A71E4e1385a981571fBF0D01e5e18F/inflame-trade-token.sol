// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./draft-ERC20Permit.sol";

contract InflameTradeToken is ERC20, ERC20Burnable, ERC20Permit {
    constructor()
        ERC20("Inflame Trade Token", "IFTT")
        ERC20Permit("Inflame Trade Token")
    {
        _mint(msg.sender, 10000000 * 10 ** decimals());
    }
}
