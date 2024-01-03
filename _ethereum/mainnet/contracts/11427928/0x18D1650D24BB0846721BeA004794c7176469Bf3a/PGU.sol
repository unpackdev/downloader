//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "./BaseMinterPauserToken.sol";

contract PGU is BaseMinterPauserToken {
    /* State Variables */
    string private constant NAME = "Polyient Games Unity";
    string private constant SYMBOL = "PGU";
    uint8 private constant DECIMALS = 18;

    /* Constructor */

    constructor(address settingsAddress)
        public
        BaseMinterPauserToken(settingsAddress, NAME, SYMBOL, DECIMALS)
    {}
}
