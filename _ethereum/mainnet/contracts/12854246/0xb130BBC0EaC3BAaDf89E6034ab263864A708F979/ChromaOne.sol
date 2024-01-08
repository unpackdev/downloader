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

contract ChromaOne is CollectCode
{
    uint8 internal constant GRID_SIZE = 1;
    constructor() ERC721("CHROMA1", "CH1") CollectCode()
    {
        config_ = Config (
            "chroma1",  // (seriesCode)
            10,         // (initialSupply)
            20,         // (maxSupply)
            100,        // (initialPrice) ETH cents
            GRID_SIZE   // (gridSize)
        );
    }
}
