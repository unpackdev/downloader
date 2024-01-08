// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./EndangeredMint.sol";

/**
 * @dev EndangeredMint implementation for the first distribution -- Rhino.
 */
contract EndangeredMintGoldenRhino is EndangeredMint {

    constructor(
        uint256 startTime_
    ) EndangeredMint("Endangered Mints Golden Rhino",
        "EM",
        "ipfs://QmNa7xWWf93trTb4ZkygpzB8Zspxscr1c3deXKdxWJLJfs/",
        startTime_,
        0x817A7c8F73a4AC6C419d2793e416a351B47BE1D2
    ) {}

}