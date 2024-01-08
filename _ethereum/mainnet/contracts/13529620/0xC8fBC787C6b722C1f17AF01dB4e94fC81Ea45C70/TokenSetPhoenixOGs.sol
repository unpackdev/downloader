// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./TokenSetRangeWithDataUpdate.sol";

contract TokenSetPhoenixOGs is TokenSetRangeWithDataUpdate {

    /**
     * Virtual range
     */
    constructor(
        address _registry,
        uint16 _traitId
        ) 
        TokenSetRangeWithDataUpdate (
            "OGs with Phoenix Trait",  // name
            10,                        // uint16 _start,
            40,                        // uint16 _end
            _registry,
            _traitId
        ) {
    }

}