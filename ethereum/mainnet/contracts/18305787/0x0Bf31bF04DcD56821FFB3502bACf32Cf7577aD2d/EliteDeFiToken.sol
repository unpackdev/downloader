// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract EliteDeFiToken is ERC20 {
    constructor() ERC20("Elite DeFi Token", "EDFT") {
        _mint(msg.sender, 100_000_000 * 10 ** decimals());
    }
}
