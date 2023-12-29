// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Token.sol";

/// @custom:security-contact security@10set.io
contract SumeragiNFT is Token {
    constructor(string memory baseURI_) Token("TGLP Sumeragi", "TGLP SUM", baseURI_) {
        //
    }
}
