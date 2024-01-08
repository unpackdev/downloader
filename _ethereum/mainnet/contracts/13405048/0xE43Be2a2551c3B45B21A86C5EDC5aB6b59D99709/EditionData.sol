//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./SafeMath.sol";

contract EditionData {
    using SafeMath for uint256;

    // -----------------------------------------------------------------------
    // STATE VARIABLES
    // -----------------------------------------------------------------------

    // Storage for each lots price
    struct LotPrice {
        uint256 pricePerEdition; // The cost per token
        uint256 maxBatchBuy; // The max amount of tokens per TX
        uint256 tokenID;
        uint256 startTime;
        uint256 endTime;
        bool biddable;
        bool useMaxStock;
        uint256 maxStock;
        uint256 tokensMinted;
    }
    // Lot ID's to price
    mapping(uint256 => LotPrice) internal lotPrices_;
}
