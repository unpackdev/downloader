// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Token.sol";

/// @custom:security-contact security@tenset.io
contract TGLPAlaskaNFT is Token {
    constructor(string memory baseURI_) Token("TGLP Alaska", "TGLP AK", baseURI_) {
        //
    }
}
