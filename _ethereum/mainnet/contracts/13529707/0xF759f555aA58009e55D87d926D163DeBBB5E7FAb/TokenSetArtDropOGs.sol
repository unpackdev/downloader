// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./TokenSet.sol";

contract TokenSetArtDropOGs is TokenSet {

    /**
     * Unordered List
     */
    constructor(
        address _registry,
        uint16 _traitId
        ) 
        TokenSet (
            "OGs with ArtDrop Trait",
            _registry,
            _traitId
        ) {
    }

}