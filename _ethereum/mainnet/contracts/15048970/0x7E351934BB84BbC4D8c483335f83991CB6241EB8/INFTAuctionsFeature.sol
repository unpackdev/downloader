// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2021 TheOpenDAO

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6;
pragma experimental ABIEncoderV2;

import "./IERC20TokenV06.sol";
import "./LibSignature.sol";

/// @dev For buy-order
interface IOnNFTReceived {
    /// @dev Alias to ERC721OrdersFeature::onERC721Received(...).
    function onERC721Received2(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4 success);
    /// @dev Alias to ERC1155OrdersFeature::onERC1155Received(...).
    function onERC1155Received2(address operator, address from, uint256 tokenId, uint256 value, bytes calldata data) external returns (bytes4 success);
}

/// @dev Feature for interacting with NFT auctions.
interface INFTAuctionsFeature {

    /// @dev Fee structure for auction.
    ///      `isMatcher` is only valid for English auctions.
    ///      For Dutch auctions, `amountOrRate` should be treated as `amount`.
    ///      For English auctions, `amountOrRate` should be treated as `rate` with precision `1 ether`.
    struct AuctionFee {
        bool isMatcher;
        address recipient;
        uint256 amountOrRate;
        bytes feeData;
    }

    /// @dev Emitted when an ERC721 Dutch auction is pre-signed.
    ///      Contains all the fields of the auction.
    event ERC721DutchAuctionPreSigned(
        address maker,
        uint128 startTime,
        uint128 endTime,
        uint256 nonce,
        IERC20TokenV06 erc20Token,
        uint256 startErc20TokenAmount,
        uint256 endErc20TokenAmount,
        AuctionFee[] fees,
        address nftToken,
        uint256 nftTokenId
    );

    /// @dev Emitted when an ERC1155 Dutch auction is pre-signed.
    ///      Contains all the fields of the auction.
    event ERC1155DutchAuctionPreSigned(
        address maker,
        uint128 startTime,
        uint128 endTime,
        uint256 nonce,
        IERC20TokenV06 erc20Token,
        uint256 startErc20TokenAmount,
        uint256 endErc20TokenAmount,
        AuctionFee[] fees,
        address nftToken,
        uint256 nftTokenId,
        uint128 nftTokenAmount
    );

    /// @dev Emitted when an ERC721 English auction is pre-signed.
    ///      Contains all the fields of the auction.
    event ERC721EnglishAuctionPreSigned(
        bool earlyMatch,
        address maker,
        uint128 startTime,
        uint128 endTime,
        uint256 nonce,
        IERC20TokenV06 erc20Token,
        uint256 startErc20TokenAmount,
        uint256 ReservedErc20TokenAmount,
        AuctionFee[] fees,
        address nftToken,
        uint256 nftTokenId
    );

    /// @dev Emitted when an ERC1155 English auction is pre-signed.
    ///      Contains all the fields of the auction.
    event ERC1155EnglishAuctionPreSigned(
        bool earlyMatch,
        address maker,
        uint128 startTime,
        uint128 endTime,
        uint256 nonce,
        IERC20TokenV06 erc20Token,
        uint256 startErc20TokenAmount,
        uint256 ReservedErc20TokenAmount,
        AuctionFee[] fees,
        address nftToken,
        uint256 nftTokenId,
        uint128 nftTokenAmount
    );

    /// @dev Emitted whenever an auction is cancelled.
    /// @param maker The maker of the auction.
    /// @param nonce The nonce of the auction that was cancelled.
    event NFTAuctionCancelled(
        address maker,
        uint256 nonce
    );

    /// @dev auction status
    enum AuctionStatus {
        INVALID_AMOUNT_SETTINGS,
        FILLABLE,
        UNFILLABLE,
        NOT_START,
        EXPIRED,
        INVALID_TIME_SETTINGS,
        INVALID_ERC1155_TOKEN_AMOUNT,
        INVALID_ERC721_TOKEN_AMOUNT,
        NATIVE_TOKEN_NOT_ALLOWED,
        TAKE_TOO_EARLY
    }

    /// @dev auction kind
    enum NFTAuctionKind {
        ENGLISH,
        DUTCH
    }

    /// @dev NFT kind
    enum NFTKind {
        ERC721,
        ERC1155
    }

    /// @dev auction info struct
    struct NFTAuctionInfo {
        bytes32 auctionStructHash;
        bytes32 auctionHash;
        AuctionStatus status;
        uint128 remainingAmount;
    }

    /// @dev Emitted whenever a Dutch auction is filled.
    /// @param nftKind Whether the auction is ERC721 or ERC1155.
    /// @param maker The maker of the auction.
    /// @param taker The taker of the auction.
    /// @param nonce The unique maker nonce in the auction.
    /// @param erc20Token The address of the ERC20 token.
    /// @param erc20FillAmount The amount of ERC20 token filled.
    /// @param nftToken The address of the NFT token.
    /// @param nftTokenId The ID of the NFT asset.
    /// @param nftTokenAmount The amount of NFT asset filled.
    event DutchAuctionFilled(
        NFTKind nftKind,
        address maker,
        address taker,
        uint256 nonce,
        IERC20TokenV06 erc20Token,
        uint256 erc20FillAmount,
        address nftToken,
        uint256 nftTokenId,
        uint128 nftTokenAmount
    );

    /// @dev Emitted whenever a English auction is filled.
    event EnglishAuctionFilled(
        NFTKind nftKind,
        bool earlyMatch,
        address auctionMaker,
        address bidMaker,
        address taker,
        uint256 nonce,
        IERC20TokenV06 erc20Token,
        uint256 erc20FillAmount,
        address nftToken,
        uint256 nftTokenId,
        uint128 nftTokenAmount
    );

    /// @dev The struct of auctions.
    ///      `earlyMatch` is only valid for English auctions.
    ///      For Dutch auctions, `endOrReservedErc20TokenAmount` should be treated as `endErc20TokenAmount`.
    ///      For English auctions, `endOrReservedErc20TokenAmount` should be treated as `reservedErc20TokenAmount`.
    struct NFTAuction {
        NFTAuctionKind auctionKind;
        NFTKind nftKind;
        bool earlyMatch;
        address maker;
        uint128 startTime;
        uint128 endTime;
        uint256 nonce;
        IERC20TokenV06 erc20Token;
        uint256 startErc20TokenAmount;
        uint256 endOrReservedErc20TokenAmount;
        AuctionFee[] fees;
        address nftToken;
        uint256 nftTokenId;
        uint128 nftTokenAmount;
    }

    /// @dev Bids for English auctions.
    struct EnglishAuctionBid {
        NFTAuction auction;
        address bidMaker;
        uint256 erc20TokenAmount;
    }

    /// @dev Get the EIP-712 hash of an English auction bid.
    /// @param enBid The English auction bid.
    /// @return bidHash The English auction bid hash.
    function getEnAuctionBidHash(EnglishAuctionBid calldata enBid) external view returns (bytes32 bidHash);

    /// @dev Bid a Dutch auction.
    function bidNFTDutchAuction(
        NFTAuction calldata dutchAuction,
        LibSignature.Signature calldata signature,
        uint128 bidAmount,
        bytes calldata callbackData
    ) external payable;

    /// @dev Get the EIP-712 hash of an auction.
    /// @param auction The auction.
    /// @return auctionHash The auction hash.
    function getNFTAuctionHash(NFTAuction calldata auction) external view returns (bytes32 auctionHash);

    /// @dev Approves an auction on-chain. After pre-signing
    ///      the auction, the `PRESIGNED` signature type will become
    ///      valid for that auction and signer.
    /// @param auction An auction.
    function preSignNFTAuction(NFTAuction calldata auction) external;
    
    /// @dev Get the info for an auction.
    /// @param auction The auction.
    /// @return auctionInfo Info about the auction.
    function getNFTAuctionInfo(NFTAuction calldata auction) 
      external view returns (NFTAuctionInfo memory auctionInfo);

    /// @dev Get the auction status bit vector for the given
    ///      maker address and nonce range.
    /// @param maker The maker of the auction.
    /// @param nonceRange Auction status bit vectors are indexed
    ///        by maker address and the upper 248 bits of the
    ///        auction nonce. We define `nonceRange` to be these
    ///        248 bits.
    /// @return bitVector The auction status bit vector for the
    ///         given maker and nonce range.
    function getAuctionStatusBitVector(address maker, uint248 nonceRange) 
      external view returns (uint256 bitVector);

    /// @dev Checks whether the given signature is valid for the
    ///      the given auction. Reverts if not.
    /// @param auction The auction.
    /// @param signature The signature to validate.
    function validateAuctionSignature(
        NFTAuction calldata auction,
        LibSignature.Signature calldata signature
    ) external view;

    /// @dev Checks whether the given signature is valid for the
    ///      the given English auction bid. Reverts if not.
    /// @param enBid The bid.
    /// @param bidSig The signature to validate.
    function validateEnAuctionBidSignature(
        EnglishAuctionBid calldata enBid,
        LibSignature.Signature calldata bidSig
    ) external view;

    /// @dev Cancel a single auction by its nonce. The caller
    ///      should be the maker of the auction. Silently succeeds if
    ///      an auction with the same nonce has already been filled or
    ///      cancelled.
    /// @param auctionNonce The auction nonce.
    function cancelAuction(uint256 auctionNonce) external;

    /// @dev Cancel multiple auctions by their nonces. The caller
    ///      should be the maker of the auctions. Silently succeeds if
    ///      an auction with the same nonce has already been filled or
    ///      cancelled.
    /// @param auctionNonces The auction nonces.
    function batchCancelAuctions(uint256[] calldata auctionNonces) external;

    /// @dev getNFTAuctionFilledAmount
    function getNFTAuctionFilledAmount(bytes32 _hash) external view returns(uint128 filledAmount);

    /// @dev isNFTAuctionFillable
    function isNFTAuctionFillable(address maker, uint256 nonce) external view returns(bool);

    /// @dev The auction maker, NFT owner, accpets a bid from a NFT buyer.
    /// @param enBid An auction bid that contains an auction entity.
    /// @param auctionSig The auction signature from the maker, NFT owner.
    /// @param bidSig The auction bid signature from the bid maker, NFT buyer.
    /// @param unwrapNativeToken If this parameter is true and the
    ///        ERC20 token of the auction is e.g. WETH, unwraps the
    ///        token before transferring it to the taker.
    /// @param takerCallbackData If this parameter is non-zero, invokes
    ///        `zeroExTakerCallback` on `msg.sender` after
    ///        the ERC20 tokens have been transferred to `msg.sender`
    ///        but before transferring the NFT asset to the buyer.
    function acceptBid(
        EnglishAuctionBid calldata enBid,
        LibSignature.Signature calldata auctionSig,
        LibSignature.Signature calldata bidSig,
        bool unwrapNativeToken,
        bytes calldata takerCallbackData
    ) external;
}
