// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./draft-ERC20Permit.sol";

contract MemiesIo is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("Memies.io", "MEMIO") ERC20Permit("Memies.io") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }
}
