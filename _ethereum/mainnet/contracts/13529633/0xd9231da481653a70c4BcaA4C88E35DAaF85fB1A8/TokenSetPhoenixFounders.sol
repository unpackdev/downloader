// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./TokenSetRangeWithDataUpdate.sol";

contract TokenSetPhoenixFounders is TokenSetRangeWithDataUpdate {

    /**
     * Virtual range
     */
    constructor(
        address _registry,
        uint16 _traitId
        ) 
        TokenSetRangeWithDataUpdate (
            "Founders with Phoenix Trait",  // name
            1000,                           // uint16 _start,
            2562,                           // uint16 _end
            _registry,
            _traitId
        ) {
    }

}