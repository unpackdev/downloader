// SPDX-License-Identifier: MIT
pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

import "./NFTAuctionsFeature.sol";
import "./IEtherTokenV06.sol";

contract NFTAuctionsFeatureHelper is NFTAuctionsFeature {

    function migrate() external override returns (bytes4 success) {
        _registerFeatureFunction(this.validateSender.selector);
        _registerFeatureFunction(this.updateAuctionState.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    constructor(address zeroExAddress, IEtherTokenV06 weth) public NFTAuctionsFeature(zeroExAddress, weth) { }

    function getAuctionTypeHash2() external pure returns (bytes32) {
        return bytes32(_AUCTION_TYPEHASH);
    }

    function getFeeTypeHash2() external pure returns (bytes32) {
        return bytes32(_FEE_TYPEHASH);
    }

    function getEnAuctionBidTypeHash2() external pure returns (bytes32) {
        return bytes32(_EN_AUCTION_BID_TYPEHASH);
    }

    function validateSender(address taker, EnglishAuctionBid memory enBid) external pure returns(bool) {
        return _validateSender(taker, enBid);
    }

    function updateAuctionState(address maker, uint256 nonce, bytes32 _hash, uint128 remaining, uint128 amount) external {
        return _updateAuctionState(maker, nonce, _hash, remaining, amount);
    }

    function getFeeTypeHash() external pure returns(bytes32) {
        return keccak256(abi.encodePacked(
            "AuctionFee(",
                "bool isMatcher,",
                "address recipient,",
                "uint256 amountOrRate,",
                "bytes feeData",
            ")"
        ));
    }

    function getAuctionTypeHash() external pure returns(bytes32) {
        return keccak256(abi.encodePacked(
            "NFTAuction(",
                "uint8 auctionKind,",
                "uint8 nftKind,",
                "bool earlyMatch,",
                "address maker,",
                "uint128 startTime,",
                "uint128 endTime,",
                "uint256 nonce,",
                "address erc20Token,",
                "uint256 startErc20TokenAmount,",
                "uint256 endOrReservedErc20TokenAmount,",
                "AuctionFee[] fees,",
                "address nftToken,",
                "uint256 nftTokenId,",
                "uint128 nftTokenAmount",
            ")",
            "AuctionFee(bool isMatcher,address recipient,uint256 amountOrRate,bytes feeData)"
        ));
    }

    // https://eips.ethereum.org/EIPS/eip-712#definition-of-encodetype
    function getEnAuctionBidTypeHash() external pure returns(bytes32) {
        return keccak256(abi.encodePacked(
            "EnglishAuctionBid(",
                "NFTAuction auction,",
                "address bidMaker,",
                "uint256 erc20TokenAmount",
            ")",
            "AuctionFee(bool isMatcher,address recipient,uint256 amountOrRate,bytes feeData)",
            "NFTAuction(uint8 auctionKind,uint8 nftKind,bool earlyMatch,address maker,uint128 startTime,uint128 endTime,uint256 nonce,address erc20Token,uint256 startErc20TokenAmount,uint256 endOrReservedErc20TokenAmount,AuctionFee[] fees,address nftToken,uint256 nftTokenId,uint128 nftTokenAmount)"
        ));
    }
}

