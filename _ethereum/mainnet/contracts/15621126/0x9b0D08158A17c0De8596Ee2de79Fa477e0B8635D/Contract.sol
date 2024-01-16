// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ERC20.sol";

contract EquityToken247 is ERC20 {
    constructor() ERC20("247", "247") {
        _mint(
            0x61839583E86bebc140F6dd3cC5Fbcf3706531f66,
            10000000000000000000000000000
        );
    }
}
