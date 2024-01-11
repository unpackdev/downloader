// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./AllowlistedNFT.sol";

/// @custom:security-contact security@pangeadao.org
contract PangeaPresaleNFT is AllowlistedNFT {
    string private constant _NAME = "Pangea Presale Contributors";
    string private constant _SYMBOL = "PNGANFT";
    string private constant _INIT_BASE_URI =
        "ipfs://Qmf4Lmn7NAdyus7vnDGR5Nq1941VHnLhfc7pSqFmSR6K9u/";

    constructor() AllowlistedNFT(_NAME, _SYMBOL, _INIT_BASE_URI) {}
}
