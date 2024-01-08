// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./TokenSetRangeWithDataUpdate.sol";

contract TokenSetPhoenixAlphas is TokenSetRangeWithDataUpdate {

    /**
     * Virtual range
     */
    constructor(
        address _registry,
        uint16 _traitId
        ) 
        TokenSetRangeWithDataUpdate (
            "Alphas with Phoenix Trait",  // name
            100,                          // uint16 _start,
            263,                          // uint16 _end
            _registry,
            _traitId
        ) {
    }

}