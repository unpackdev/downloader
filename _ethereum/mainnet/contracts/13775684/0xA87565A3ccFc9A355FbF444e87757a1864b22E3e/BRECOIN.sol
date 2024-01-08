// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20FlexibleCappedSupply.sol";

contract BRECOIN is ERC20FlexibleCappedSupply {
    constructor()
        ERC20FlexibleCappedSupply(
            "BRECOIN",
            "BRE",
            50000000000 * 10**18,
            500000000 * 10**18
        )
    {}
}
