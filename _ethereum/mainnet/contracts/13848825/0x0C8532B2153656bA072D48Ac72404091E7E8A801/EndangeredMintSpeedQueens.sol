// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./EndangeredMint.sol";

/**
 * @dev EndangeredMint implementation for the first distribution -- Rhino.
 */
contract EndangeredMintSpeedQueens is EndangeredMint {

    constructor(
        uint256 startTime_
    ) EndangeredMint("Endangered Mints Speed Queens",
        "EM",
        "ipfs://QmPtDo58NoGgTCvGt8dNqPSJeL3coATY3BMeidNxWpk3p2/",
        startTime_,
        0x817A7c8F73a4AC6C419d2793e416a351B47BE1D2
    ) {}

}