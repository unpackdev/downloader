// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./TokenSetRangeReadonly.sol";

contract TokenSetFounders is TokenSetRangeReadonly {

    /**
     * Virtual range
     */
    constructor() TokenSetRangeReadonly(
            "Founders 1000 to 9999",    // name
            1000,                       // uint16 _start,
            9999                        // uint16 _end
        ) {
    }

}