//
// CollectCode v1.0
// CHROMA Collection, 2021
// https://collect-code.com/
// https://twitter.com/CollectCoder
//

// SPDX-License-Identifier: MIT
// Same version as openzeppelin 3.4
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./CollectCode.sol";
import "./Utils.sol";

contract ChromaFive is CollectCode
{
    uint8 internal constant GRID_SIZE = 5;
    constructor() ERC721("CHROMA5", "CH5") CollectCode()
    {
        config_ = Config (
            "chroma5",  // (seriesCode)
            50,         // (initialSupply)
            100,        // (maxSupply)
            1,          // (initialPrice) ETH cents
            GRID_SIZE   // (gridSize)
        );
    }
}
