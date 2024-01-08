// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./TokenSetRangeReadonly.sol";

contract TokenSetOGs is TokenSetRangeReadonly {

    /**
     * Virtual range
     */
    constructor() TokenSetRangeReadonly(
            "OGs 10 to 99",             // name
            10,                         // uint16 _start,
            99                          // uint16 _end
        ) {
    }

}