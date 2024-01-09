// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20('Artifacts Protocol Token', 'ARTIFACT') {
        super._mint(_msgSender(), 1000000000 * (10**super.decimals()));
    }
}
