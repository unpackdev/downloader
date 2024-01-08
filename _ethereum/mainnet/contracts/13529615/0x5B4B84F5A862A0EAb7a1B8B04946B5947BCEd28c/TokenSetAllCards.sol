// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./TokenSetRangeReadonly.sol";

contract TokenSetAllCards is TokenSetRangeReadonly {

    /**
     * Virtual range
     */
    constructor() TokenSetRangeReadonly(
            "All EtherCards except Creators", // name
            10,   // uint16 _start,
            9999  // uint16 _end
        ) {
    }

}