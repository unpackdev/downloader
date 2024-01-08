// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "./GMsDerivativeBase.sol";

contract GenerativemasksGirl is GMsDerivativeBase {

    constructor(
        string memory baseURI,
        address _derivedFrom
    )
    GMsDerivativeBase(
        "Generativemasks Girl",
        "GMGIRL",
        baseURI,
        address(0x80416304142Fa37929f8A4Eee83eE7D2dAc12D7c),
        _derivedFrom
    )
    {}

}
