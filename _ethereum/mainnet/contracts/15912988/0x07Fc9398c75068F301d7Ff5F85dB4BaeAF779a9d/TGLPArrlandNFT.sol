// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Token.sol";

/// @custom:security-contact security@10set.io
contract TGLPArrlandNFT is Token {
    constructor(string memory baseURI_) Token("TGLP Arrland", "TGLP AR", baseURI_) {
        //
    }
}
