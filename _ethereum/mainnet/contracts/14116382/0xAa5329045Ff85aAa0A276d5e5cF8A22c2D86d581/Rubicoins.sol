// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./RubiToken.sol";

/// @custom:security-contact https://telum.tech

contract Rubicoin is RubiToken {
    function initialize() initializer public override {
        __ERC20_init("Rubicoin", "RUBI");
        super.initialize();
    }
}

contract RubicoinLite is RubiToken {
    function initialize() initializer public override {
        __ERC20_init("Rubicoin Lite", "RUBL");
        super.initialize();
    }
}
