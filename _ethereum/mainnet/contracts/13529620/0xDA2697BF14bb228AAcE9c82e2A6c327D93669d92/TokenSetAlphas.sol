// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./TokenSetRangeReadonly.sol";

contract TokenSetAlphas is TokenSetRangeReadonly {

    /**
     * Virtual range
     */
    constructor() TokenSetRangeReadonly(
            "Alphas 100 to 999",        // name
            100,                        // uint16 _start,
            999                         // uint16 _end
        ) {
    }

}