// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./TokenSet.sol";

contract TokenSetArtDropAlphas is TokenSet {

    /**
     * Unordered List
     */
    constructor(
        address _registry,
        uint16 _traitId
        ) 
        TokenSet (
            "Alphas with ArtDrop Trait",
            _registry,
            _traitId
        ) {
    }

}