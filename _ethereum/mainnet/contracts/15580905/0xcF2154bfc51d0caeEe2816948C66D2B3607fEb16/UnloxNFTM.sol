// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTM.sol";
import "./NFTMBrowsable.sol";
import "./NFTMPromotion.sol";
import "./NFTMTokenMarketFee.sol";

contract UnloxNFTM is NFTM, NFTMBrowsable, NFTMPromotion, NFTMTokenMarketFee {


constructor(address feeCollector, uint256 marketFeeCoin, uint256 marketFeeCENT) NFTM(feeCollector, marketFeeCENT) {
        _marketFeeCoin = marketFeeCoin;
    }
}