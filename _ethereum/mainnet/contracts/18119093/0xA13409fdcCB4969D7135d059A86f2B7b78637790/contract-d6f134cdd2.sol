// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

/// @custom:security-contact info@veniceswap.com
contract SpontalezaToken is ERC20 {
    constructor() ERC20("Spontaleza Token", "SPONT") {
        _mint(msg.sender, 4500000000 * 10 ** decimals());
    }
}
