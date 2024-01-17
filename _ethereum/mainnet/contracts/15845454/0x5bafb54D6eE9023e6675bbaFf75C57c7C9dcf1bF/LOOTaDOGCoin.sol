// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";

contract LOOTaDOGCoin is ERC20 {
    constructor() ERC20("LOOTaDOGCoin", "LADC") {
        _mint(msg.sender, 600000000000000000);
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }
}
