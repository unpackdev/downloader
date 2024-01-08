// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./draft-ERC20Permit.sol";

contract MetaFabric is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("MetaFabric", "FABRIC") ERC20Permit("MetaFabric") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}
