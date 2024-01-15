// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

/// @custom:security-contact investor@cryptoone.farm
contract ConeToken is ERC20 {
    constructor() ERC20("CRYPTO ONE", "CONE") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}