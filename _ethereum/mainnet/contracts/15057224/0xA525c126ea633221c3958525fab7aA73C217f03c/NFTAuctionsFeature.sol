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

import "./IEtherTokenV06.sol";
import "./LibSafeMathV06.sol";
import "./LibMathV06.sol";
import "./FixinERC721Spender.sol";
import "./FixinERC1155Spender.sol";
import "./FixinTokenSpender.sol";
import "./LibMigrate.sol";
import "./IFeature.sol";
import "./INFTAuctionsFeature.sol";
import "./FixinEIP712.sol";
import "./FixinCommon.sol";
import "./LibNFTOrdersRichErrors.sol";
import "./LibSignature.sol";
import "./LibNFTAuctionsStorage.sol";
import "./ITakerCallback.sol";
import "./IFeeRecipient.sol";

/// @dev Feature for interacting with NFT auctions.
contract NFTAuctionsFeature is
    IFeature,
    FixinERC721Spender,
    FixinERC1155Spender,
    FixinTokenSpender,
    FixinEIP712,
    FixinCommon,
    INFTAuctionsFeature
{
    using LibSafeMathV06 for uint256;
    using LibSafeMathV06 for uint128;

    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "Auctions";

    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(1, 0, 0);

    /// @dev Native token pseudo-address.
    address constant private NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev protocol head for ERC721
    uint256 private constant CODE_ERC721  = 10000;

    /// @dev protocol head for ERC1155
    uint256 private constant CODE_ERC1155 = 20000;
    
    /// @dev protocol head for auction
    uint256 private constant CODE_AUCTION = 30000;

    /// @dev The WETH token contract.
    IEtherTokenV06 private immutable WETH;

    // keccak256(abi.encodePacked(
    //     "NFTAuction(",
    //         "uint8 auctionKind,",
    //         "uint8 nftKind,",
    //         "bool earlyMatch,",
    //         "address maker,",
    //         "uint128 startTime,",
    //         "uint128 endTime,",
    //         "uint256 nonce,",
    //         "address erc20Token,",
    //         "uint256 startErc20TokenAmount,",
    //         "uint256 endOrReservedErc20TokenAmount,",
    //         "AuctionFee[] fees,",
    //         "address nftToken,",
    //         "uint256 nftTokenId,",
    //         "uint128 nftTokenAmount",
    //     ")",
    //     "AuctionFee(bool isMatcher,address recipient,uint256 amountOrRate,bytes feeData)"
    // ));
    uint256 constant internal _AUCTION_TYPEHASH = 0x34d7d43b53221ee6752fa32d5ded36b33e740caf3f63cebc727ecf4cdf3e33b2;

    // keccak256(abi.encodePacked(
    //     "AuctionFee(",
    //         "bool isMatcher,",
    //         "address recipient,",
    //         "uint256 amountOrRate,",
    //         "bytes feeData",
    //     ")"
    // ));
    uint256 constant internal _FEE_TYPEHASH = 0x2b140d7226cf6abe7e4444eda0a7193418f3834740d024075cc30e873e6e970e;

    // keccak256(abi.encodePacked(
    //     "EnglishAuctionBid(",
    //         "NFTAuction auction,",
    //         "address bidMaker,",
    //         "uint256 erc20TokenAmount",
    //     ")",
    //     "AuctionFee(bool isMatcher,address recipient,uint256 amountOrRate,bytes feeData)",
    //     "NFTAuction(uint8 auctionKind,uint8 nftKind,bool earlyMatch,address maker,uint128 startTime,uint128 endTime,uint256 nonce,address erc20Token,uint256 startErc20TokenAmount,uint256 endOrReservedErc20TokenAmount,AuctionFee[] fees,address nftToken,uint256 nftTokenId,uint128 nftTokenAmount)"
    // ));
    uint256 constant internal _EN_AUCTION_BID_TYPEHASH = 0x0e81d1fc9d2f6b4a2129ba40325ec3a851f3a0c7dd470bcccbd624c4defee146;

    // Mask of the lower 20 bytes of a bytes32.
    uint256 private constant ADDRESS_MASK = (1 << 160) - 1;

    // keccak256("");
    bytes32 private constant _EMPTY_ARRAY_KECCAK256 = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    /// @dev The magic return value indicating the success of a `receiveZeroExFeeCallback`.
    bytes4 private constant FEE_CALLBACK_MAGIC_BYTES = IFeeRecipient.receiveZeroExFeeCallback.selector;

    /// @dev The magic return value indicating the success of a `zeroExTakerCallback`.
    bytes4 private constant TAKER_CALLBACK_MAGIC_BYTES = ITakerCallback.zeroExTakerCallback.selector;

    constructor(address zeroExAddress, IEtherTokenV06 weth) public FixinEIP712(zeroExAddress) {
        WETH = weth;
    }

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external virtual returns (bytes4 success) {
        _registerFeatureFunction(this.bidNFTDutchAuction.selector);
        _registerFeatureFunction(this.getNFTAuctionHash.selector);
        _registerFeatureFunction(this.preSignNFTAuction.selector);
        _registerFeatureFunction(this.getNFTAuctionInfo.selector);
        _registerFeatureFunction(this.getAuctionStatusBitVector.selector);
        _registerFeatureFunction(this.validateAuctionSignature.selector);
        _registerFeatureFunction(this.validateEnAuctionBidSignature.selector);
        _registerFeatureFunction(this.cancelAuction.selector);
        _registerFeatureFunction(this.batchCancelAuctions.selector);
        _registerFeatureFunction(this.getEnAuctionBidHash.selector);
        _registerFeatureFunction(this.acceptBid.selector);
        _registerFeatureFunction(this.onERC721Received.selector);
        _registerFeatureFunction(this.onERC1155Received.selector);
        _registerFeatureFunction(this.getNFTAuctionFilledAmount.selector);
        _registerFeatureFunction(this.isNFTAuctionFillable.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Bid a Dutch auction.
    function bidNFTDutchAuction(
        NFTAuction memory auction,
        LibSignature.Signature memory signature,
        uint128 bidAmount,
        bytes memory callbackData
    ) external override payable {
        uint256 ethBalanceBefore = address(this).balance.safeSub(msg.value);
        uint256 erc20FillAmount = _bidDutchAuction(
            msg.sender, // taker
            auction,
            signature,
            bidAmount,
            msg.value,
            callbackData
        );
        
        {
            uint256 ethBalanceAfter = address(this).balance;
            // Cannot use pre-existing ETH balance
            if (ethBalanceAfter < ethBalanceBefore) {
                // Unreachable code
                LibNFTOrdersRichErrors.OverspentEthError(
                    msg.value + (ethBalanceBefore - ethBalanceAfter),
                    msg.value
                ).rrevert();
            }
            // Refund
            _transferEth(msg.sender, ethBalanceAfter - ethBalanceBefore);
        }

        emit DutchAuctionFilled(
            auction.nftKind,
            auction.maker,
            msg.sender, // taker
            auction.nonce,
            auction.erc20Token,
            erc20FillAmount,
            auction.nftToken,
            auction.nftTokenId,
            auction.nftTokenAmount
        );
    }

    function _bidDutchAuction(
        address taker,
        NFTAuction memory auction,
        LibSignature.Signature memory signature,
        uint128 bidAmount,
        uint256 ethAvailable,
        bytes memory takerCallbackData
    ) private returns (uint256 erc20FillAmount) {
        require(auction.auctionKind == NFTAuctionKind.DUTCH, "NFTAuctionsFeature::bidNFTDutchAuction/AUCTION_KIND_NOT_DUTCH");

        NFTAuctionInfo memory auctionInfo = getNFTAuctionInfo(auction);

        // Check that the auction can be filled.
        _validateNFTAuction(auction, signature, auctionInfo, bidAmount);
       
        _updateAuctionState(auction.maker, auction.nonce, auctionInfo.auctionHash, auctionInfo.remainingAmount, bidAmount);

        // Rounding favors the auction maker.
        erc20FillAmount = LibMathV06.getPartialAmountCeil(
            auction.endTime.safeSub(block.timestamp),
            auction.endTime.safeSub(auction.startTime),
            auction.startErc20TokenAmount.safeSub(auction.endOrReservedErc20TokenAmount) // as endErc20TokenAmount
        ).safeAdd(auction.endOrReservedErc20TokenAmount); // as endErc20TokenAmount

        if (bidAmount != auction.nftTokenAmount) {
            // Rounding favors the auction maker.
            erc20FillAmount = LibMathV06.getPartialAmountCeil(
                bidAmount,
                auction.nftTokenAmount,
                erc20FillAmount
            );
        }

        if (auction.nftKind == NFTKind.ERC721) {
            _transferERC721AssetFrom(IERC721Token(auction.nftToken), auction.maker, taker, auction.nftTokenId);
        } else {
            _transferERC1155AssetFrom(IERC1155Token(auction.nftToken), auction.maker, taker, auction.nftTokenId, bidAmount);
        }
        
        if (takerCallbackData.length > 0) {
            require(
                taker != address(this),
                "NFTAuctionsFeature::_bidDutchAuction/CANNOT_CALLBACK_SELF"
            );
            uint256 ethBalanceBeforeCallback = address(this).balance;
            // Invoke the callback
            bytes4 callbackResult = ITakerCallback(taker)
                .zeroExTakerCallback(auctionInfo.auctionHash, takerCallbackData);
            // Update `ethAvailable` with amount acquired during the callback
            ethAvailable = ethAvailable.safeAdd(
                address(this).balance.safeSub(ethBalanceBeforeCallback)
            );
            // Check for the magic success bytes
            require(
                callbackResult == TAKER_CALLBACK_MAGIC_BYTES,
                "NFTAuctionsFeature::_bidDutchAuction/CALLBACK_FAILED"
            );
        }

        if (address(auction.erc20Token) == NATIVE_TOKEN_ADDRESS) {
            // Transfer ETH to the seller.
            _transferEth(payable(auction.maker), erc20FillAmount);

            // Fees are paid from the EP's current balance of ETH.
            _payEthFees(
                auction,
                erc20FillAmount,
                ethAvailable
            );
        } else if (auction.erc20Token == WETH) {
            // If there is enough ETH available, fill the WETH auction
            // (including fees) using that ETH.
            // Otherwise, transfer WETH from the taker.
            if (ethAvailable >= erc20FillAmount) {
                // Wrap ETH.
                WETH.deposit{value: erc20FillAmount}();
                // TODO: Probably safe to just use WETH.transfer for some
                //       small gas savings
                // Transfer WETH to the seller.
                _transferERC20Tokens(
                    WETH,
                    auction.maker,
                    erc20FillAmount
                );
                // Fees are paid from the EP's current balance of ETH.
                _payEthFees(
                    auction,
                    erc20FillAmount,
                    ethAvailable
                );
            } else {
                // Transfer WETH from the buyer to the seller.
                _transferERC20TokensFrom(
                    auction.erc20Token,
                    taker,
                    auction.maker,
                    erc20FillAmount
                );
                // The buyer pays fees using WETH.
                _payFees(
                    auction,
                    taker,
                    erc20FillAmount,
                    false
                );
            }
        } else {
            // Transfer ERC20 token from the buyer to the seller.
            _transferERC20TokensFrom(
                auction.erc20Token,
                taker,
                auction.maker,
                erc20FillAmount
            );
            // The buyer pays fees.
            _payFees(
                auction,
                taker,
                erc20FillAmount,
                false
            );
        }
    }

    function _payEthFees(
        NFTAuction memory auction,
        uint256 erc20FillAmount,
        uint256 ethAvailable
    ) private {
        // Pay fees using ETH.
        uint256 ethFees = _payFees(
            auction,
            address(this),
            erc20FillAmount,
            true
        );
        // Calc amount of ETH spent.
        uint256 ethSpent = erc20FillAmount.safeAdd(ethFees);
        if (ethSpent > ethAvailable) {
            LibNFTOrdersRichErrors.OverspentEthError(
                ethSpent,
                ethAvailable
            ).rrevert();
        }
    }

    function _payFees(
        NFTAuction memory auction,
        address payer,
        uint256 erc20FillAmount,
        bool useNativeToken
    ) private returns (uint256 totalFeesPaid) {
        // Make assertions about ETH case
        if (useNativeToken) {
            assert(payer == address(this));
            assert(
                auction.erc20Token == WETH ||
                address(auction.erc20Token) == NATIVE_TOKEN_ADDRESS
            );
        }

        for (uint256 i = 0; i < auction.fees.length; ++i) {
            AuctionFee memory fee = auction.fees[i];

            require(
                fee.recipient != address(this),
                "NFTAuctionsFeature::_payFees/RECIPIENT_CANNOT_BE_EXCHANGE_PROXY"
            );

            if (fee.amountOrRate == 0 || erc20FillAmount == 0) {
                continue;
            }
            uint256 feeFillAmount;
            if (auction.auctionKind == NFTAuctionKind.DUTCH) {
                // Round against the fee recipient
                feeFillAmount = LibMathV06.getPartialAmountFloor(
                    erc20FillAmount,
                    auction.startErc20TokenAmount,
                    fee.amountOrRate // as amount
                );
            } else {
                // Round against the fee recipient
                feeFillAmount = LibMathV06.getPartialAmountFloor(
                    fee.amountOrRate, // as rate with precision `1 ether`
                    1 ether,
                    erc20FillAmount
                );
            }
            if (feeFillAmount == 0) {
                continue;
            }

            if (useNativeToken) {
                // Transfer ETH to the fee recipient.
                _transferEth(payable(fee.recipient), feeFillAmount);
            } else {
                // Transfer ERC20 token from payer to recipient.
                _transferERC20TokensFrom(
                    auction.erc20Token,
                    payer,
                    fee.recipient,
                    feeFillAmount
                );
            }
            // Note that the fee callback is _not_ called if zero
            // `feeData` is provided. If `feeData` is provided, we assume
            // the fee recipient is a contract that implements the
            // `IFeeRecipient` interface.
            if (fee.feeData.length > 0) {
                // Invoke the callback
                bytes4 callbackResult = IFeeRecipient(fee.recipient).receiveZeroExFeeCallback(
                    useNativeToken ? NATIVE_TOKEN_ADDRESS : address(auction.erc20Token),
                    feeFillAmount,
                    fee.feeData
                );
                // Check for the magic success bytes
                require(
                    callbackResult == FEE_CALLBACK_MAGIC_BYTES,
                    "NFTAuctionsFeature::_payFees/CALLBACK_FAILED"
                );
            }
            // Sum the fees paid
            totalFeesPaid = totalFeesPaid.safeAdd(feeFillAmount);
        }
    }

    /// @dev Cancel a single auction by its nonce. The caller
    ///      should be the maker of the auction. Silently succeeds if
    ///      an auction with the same nonce has already been filled or
    ///      cancelled.
    /// @param auctionNonce The auction nonce.
    function cancelAuction(uint256 auctionNonce) public override {
        // get the low 8 bits as a flag.
        uint256 flag = 1 << (auctionNonce & 255);
        LibNFTAuctionsStorage.Storage storage stor = LibNFTAuctionsStorage.getStorage();
        // get the high 248 bits as an index.
        // set the flag corresponding to the index.
        stor.auctionCancellationByMaker[msg.sender][uint248(auctionNonce >> 8)] |= flag;
        emit NFTAuctionCancelled(msg.sender, auctionNonce);
    }

    /// @dev Cancel multiple auctions by their nonces. The caller
    ///      should be the maker of the auctions. Silently succeeds if
    ///      an auction with the same nonce has already been filled or
    ///      cancelled.
    /// @param auctionNonces The auction nonces.
    function batchCancelAuctions(uint256[] calldata auctionNonces) external override {
        uint256 len = auctionNonces.length;
        for (uint256 i = 0; i < len; ++i) {
            cancelAuction(auctionNonces[i]);
        }
    }

    function _updateAuctionState(address maker, uint256 nonce, bytes32 _hash, uint128 remaining, uint128 amount) internal {
        LibNFTAuctionsStorage.Storage storage stor = LibNFTAuctionsStorage.getStorage();
        if (remaining == amount) {
            uint256 flag = 1 << (nonce & 255);
            stor.auctionCancellationByMaker[maker][uint248(nonce >> 8)] |= flag;
        } else {
            uint128 filledAmount = stor.auctionState[_hash].filledAmount;
            stor.auctionState[_hash].filledAmount = filledAmount.safeAdd128(amount);
        }
    }

    /// @dev getNFTAuctionFilledAmount
    function getNFTAuctionFilledAmount(bytes32 _hash) external override view virtual returns(uint128 filledAmount) {
        LibNFTAuctionsStorage.Storage storage stor = LibNFTAuctionsStorage.getStorage();
        filledAmount = stor.auctionState[_hash].filledAmount;
    }

    /// @dev isNFTAuctionFillable
    function isNFTAuctionFillable(address maker, uint256 nonce) external override virtual view returns(bool) {
        LibNFTAuctionsStorage.Storage storage stor = LibNFTAuctionsStorage.getStorage();
        uint256 auctionCancellationBitVector = stor.auctionCancellationByMaker[maker][uint248(nonce >> 8)];
        uint256 flag = 1 << (nonce & 255);
        return auctionCancellationBitVector & flag == 0;
    }

    /// @dev Get the info for an auction.
    /// @param auction The auction.
    /// @return auctionInfo Info about the auction.
    function getNFTAuctionInfo(NFTAuction memory auction) public override view returns (NFTAuctionInfo memory auctionInfo) {
        auctionInfo.auctionStructHash = _getNFTAuctionStructHash(auction);
        auctionInfo.auctionHash = _getEIP712Hash(auctionInfo.auctionStructHash);

        if (auction.nftKind == NFTKind.ERC721) {
            if (auction.nftTokenAmount != 1) {
                auctionInfo.status = AuctionStatus.INVALID_ERC721_TOKEN_AMOUNT;
                return auctionInfo;
            }
        } else {
            if (auction.nftTokenAmount == 0) {
                auctionInfo.status = AuctionStatus.INVALID_ERC1155_TOKEN_AMOUNT;
                return auctionInfo;
            }
        }

        if (auction.endTime <= auction.startTime) {
            auctionInfo.status = AuctionStatus.INVALID_TIME_SETTINGS;
            return auctionInfo;
        } else if (block.timestamp < auction.startTime) {
            auctionInfo.status = AuctionStatus.NOT_START;
            return auctionInfo;
        }

        if (auction.auctionKind == NFTAuctionKind.DUTCH) {
            if (auction.endTime < block.timestamp) {
                auctionInfo.status = AuctionStatus.EXPIRED;
                return auctionInfo;
            } else if (auction.endOrReservedErc20TokenAmount >= auction.startErc20TokenAmount) { // as endErc20TokenAmount
                auctionInfo.status = AuctionStatus.INVALID_AMOUNT_SETTINGS;
                return auctionInfo;
            }
        } else {
            if (address(auction.erc20Token) == NATIVE_TOKEN_ADDRESS) {
                auctionInfo.status = AuctionStatus.NATIVE_TOKEN_NOT_ALLOWED;
                return auctionInfo;
            } else if (!auction.earlyMatch && block.timestamp <= auction.endTime) {
                auctionInfo.status = AuctionStatus.TAKE_TOO_EARLY;
                return auctionInfo;
            }
        }

        LibNFTAuctionsStorage.Storage storage stor = LibNFTAuctionsStorage.getStorage();

        // drop the low 8 bits to get the auctionStatusBitVector index.
        uint256 auctionCancellationBitVector = stor.auctionCancellationByMaker[auction.maker][uint248(auction.nonce >> 8)];
        // use the low 8 bits to index auctionCancellationBitVector.
        uint256 flag = 1 << (auction.nonce & 255);
        if (auctionCancellationBitVector & flag != 0) {
            auctionInfo.status = AuctionStatus.UNFILLABLE;
            return auctionInfo;
        }

        if (auction.nftKind == NFTKind.ERC1155) {
            LibNFTAuctionsStorage.AuctionState storage auctionState = stor.auctionState[auctionInfo.auctionHash];
            auctionInfo.remainingAmount = auction.nftTokenAmount.safeSub128(auctionState.filledAmount);
        } else {
            auctionInfo.remainingAmount = 1;
        }

        // Otherwise, the auction is fillable.
        auctionInfo.status = AuctionStatus.FILLABLE;
    }

    /// @dev Get the auction status bit vector for the given
    ///      maker address and nonce range.
    /// @param maker The maker of the auction.
    /// @param nonceRange Auction status bit vectors are indexed
    ///        by maker address and the upper 248 bits of the
    ///        auction nonce. We define `nonceRange` to be these
    ///        248 bits.
    /// @return bitVector The auction status bit vector for the
    ///         given maker and nonce range.
    function getAuctionStatusBitVector(address maker, uint248 nonceRange) external override view returns (uint256 bitVector) {
        LibNFTAuctionsStorage.Storage storage stor = LibNFTAuctionsStorage.getStorage();
        return stor.auctionCancellationByMaker[maker][nonceRange];
    }

    function _validateNFTAuction(
        NFTAuction memory auction,
        LibSignature.Signature memory signature,
        NFTAuctionInfo memory auctionInfo,
        uint128 bidAmount
    ) private view {
        if(auction.nftKind == NFTKind.ERC721) {
            require(bidAmount == 1, "NFTAuctionsFeature::_validateNFTAuction/INVALID_ERC721_BID_AMOUNT");
        } else {
            require(bidAmount >= 1, "NFTAuctionsFeature::_validateNFTAuction/INVALID_ERC1155_BID_AMOUNT");
        }

        // Check that the auction is valid and has not expired, been cancelled, or been filled.
        if (auctionInfo.status != AuctionStatus.FILLABLE) {
            LibNFTOrdersRichErrors.OrderNotFillableError(
                auction.maker,
                auction.nonce,
                uint8(auctionInfo.status)
            ).rrevert();
        }

        if (bidAmount > auctionInfo.remainingAmount) {
            LibNFTOrdersRichErrors.ExceedsRemainingOrderAmount(
                auctionInfo.remainingAmount,
                bidAmount
            ).rrevert();
        }

        // Check the signature.
        _validateAuctionSignature(auctionInfo.auctionHash, signature, auction.maker);
    }

    /// @dev Checks whether the given signature is valid for the
    ///      the given auction. Reverts if not.
    /// @param auction The auction.
    /// @param signature The signature to validate.
    function validateAuctionSignature(
        NFTAuction memory auction,
        LibSignature.Signature memory signature
    ) external override view {
        bytes32 _hash = getNFTAuctionHash(auction);
        _validateAuctionSignature(_hash, signature, auction.maker);
    }

    /// @dev Checks whether the given signature is valid for the
    ///      the given English auction bid. Reverts if not.
    /// @param enBid The bid.
    /// @param bidSig The signature to validate.
    function validateEnAuctionBidSignature(
        EnglishAuctionBid memory enBid,
        LibSignature.Signature memory bidSig
    ) external override view {
        bytes32 auctionStructHash = _getNFTAuctionStructHash(enBid.auction);
        _validateEnAuctionBidSignature(auctionStructHash, enBid, bidSig);
    }

    function _validateEnAuctionBidSignature(
        bytes32 auctionStructHash,
        EnglishAuctionBid memory enBid,
        LibSignature.Signature memory bidSig
    ) private view {
        require(
            bidSig.signatureType != LibSignature.SignatureType.PRESIGNED, 
            "NFTAuctionsFeature::_validateEnAuctionBidSignature/SIGNATURE_TYPE_CANNOT_BE_PRESIGNED"
        );
        bytes32 _hash = _getEIP712Hash(_getEnAuctionBidStructHash(enBid, auctionStructHash));
        _validateAuctionSignature(_hash, bidSig, enBid.bidMaker);
    }
    
    function _validateAuctionSignature(
        bytes32 auctionHash,
        LibSignature.Signature memory signature,
        address maker
    ) private view {
        if (signature.signatureType == LibSignature.SignatureType.PRESIGNED) {
            // Check if auction hash has been pre-signed by the maker.
            bool isPreSigned = LibNFTAuctionsStorage.getStorage().auctionState[auctionHash].preSigned;
            if (!isPreSigned) {
                LibNFTOrdersRichErrors.InvalidSignerError(maker, address(0)).rrevert();
            }
        } else {
            address signer = LibSignature.getSignerOfHash(auctionHash, signature);
            if (signer != maker) {
                LibNFTOrdersRichErrors.InvalidSignerError(maker, signer).rrevert();
            }
        }
    }

    /// @dev Get the EIP-712 hash of an auction.
    /// @param auction The auction.
    /// @return auctionHash The auction hash.
    function getNFTAuctionHash(NFTAuction memory auction) public override view returns (bytes32 auctionHash) {
        return _getEIP712Hash(_getNFTAuctionStructHash(auction));
    }

    /// @dev Get the EIP-712 hash of an English auction bid.
    /// @param enBid The English auction bid.
    /// @return bidHash The English auction bid hash.
    function getEnAuctionBidHash(EnglishAuctionBid memory enBid) external override view returns (bytes32 bidHash) {
        bytes32 auctionHash = _getNFTAuctionStructHash(enBid.auction);
        return _getEIP712Hash(_getEnAuctionBidStructHash(enBid, auctionHash));
    }

    function _getNFTAuctionStructHash(NFTAuction memory auction) private pure returns (bytes32 structHash) {
        bytes32 feesHash = _feesHash(auction.fees);
        // Hash in place, equivalent to:
        // return keccak256(abi.encode(
        //     _AUCTION_TYPEHASH,-1
        //     uint8 auctionKind;0
        //     uint8 nftKind;1
        //     bool earlyMatch;2
        //     address maker;3
        //     uint128 startTime;4
        //     uint128 endTime;
        //     uint256 nonce;
        //     address erc20Token;
        //     uint256 startErc20TokenAmount;
        //     uint256 endOrReservedErc20TokenAmount;
        //     AuctionFee[] fees;10
        //     address nftToken;
        //     uint256 nftTokenId;
        //     uint128 nftTokenAmount;13
        // ));
        assembly {
            if lt(auction, 32) { invalid() } // Don't underflow memory.

            let typeHashPos := sub(auction, 32) // auction - 32
            let feesHashPos := add(auction, 320) // auction + (32 * 10)

            let typeHashMemBefore := mload(typeHashPos)
            let feeHashMemBefore := mload(feesHashPos)

            mstore(typeHashPos, _AUCTION_TYPEHASH)
            mstore(feesHashPos, feesHash)
            structHash := keccak256(typeHashPos, 480 /* 32 * 15 */ )

            mstore(typeHashPos, typeHashMemBefore)
            mstore(feesHashPos, feeHashMemBefore)
        }
        return structHash;
    }

    function _getEnAuctionBidStructHash(EnglishAuctionBid memory enBid, bytes32 auctionHash) private pure returns (bytes32 structHash) {
        // Hash in place, equivalent to:
        // return keccak256(abi.encode(
        //     _EN_AUCTION_BID_TYPEHASH,-1
        //     NFTAuction auction;0
        //     address bidMaker;1
        //     uint256 erc20TokenAmount;2
        // ));
        assembly {
            if lt(enBid, 32) { invalid() } // Don't underflow memory.

            let typeHashPos := sub(enBid, 32) // auction - 32
            let auctionHashPos := enBid // auction

            let typeHashMemBefore := mload(typeHashPos)
            let auctionHashMemBefore := mload(auctionHashPos)

            mstore(typeHashPos, _EN_AUCTION_BID_TYPEHASH)
            mstore(auctionHashPos, auctionHash)
            structHash := keccak256(typeHashPos, 128 /* 32 * 4 */ )

            mstore(typeHashPos, typeHashMemBefore)
            mstore(auctionHashPos, auctionHashMemBefore)
        }
        return structHash;
    }

    // Hashes the `fees` array as part of computing the EIP-712 hash of an auction.
    function _feesHash(AuctionFee[] memory fees) private pure returns (bytes32 feesHash) {
        uint256 numFees = fees.length;
        // We give `fees.length == 0` and `fees.length == 1`
        // special treatment because we expect these to be the most common.
        if (numFees == 0) {
            feesHash = _EMPTY_ARRAY_KECCAK256;
        } else if (numFees == 1) {
            // feesHash = keccak256(abi.encodePacked(keccak256(abi.encode(
            //     _FEE_TYPEHASH,0,0
            //     fees[0].isMatcher,1,32
            //     fees[0].recipient,2,64
            //     fees[0].amountOrRate,3,96
            //     keccak256(fees[0].feeData)4,128
            // ))));
            AuctionFee memory fee = fees[0];
            bytes32 dataHash = keccak256(fee.feeData);
            assembly {
                // Load free memory pointer
                let mem := mload(64)
                mstore(mem, _FEE_TYPEHASH)
                // fee.isMatcher
                mstore(add(mem, 32), mload(fee))
                // fee.recipient
                mstore(add(mem, 64), and(ADDRESS_MASK, mload(add(fee, 32))))
                // fee.amountOrRate
                mstore(add(mem, 96), mload(add(fee, 64)))
                // keccak256(fee.feeData)
                mstore(add(mem, 128), dataHash)
                mstore(mem, keccak256(mem, 160))
                feesHash := keccak256(mem, 32)
            }
        } else {
            bytes32[] memory feeStructHashArray = new bytes32[](numFees);
            for (uint256 i = 0; i < numFees; i++) {
                feeStructHashArray[i] = keccak256(abi.encode(
                    _FEE_TYPEHASH,
                    fees[i].isMatcher,
                    fees[i].recipient,
                    fees[i].amountOrRate,
                    keccak256(fees[i].feeData)
                ));
            }
            assembly {
                feesHash := keccak256(add(feeStructHashArray, 32), mul(numFees, 32))
            }
        }
    }

    /// @dev Approves an auction on-chain. After pre-signing
    ///      the auction, the `PRESIGNED` signature type will become
    ///      valid for that auction and signer.
    /// @param auction An auction.
    function preSignNFTAuction(NFTAuction memory auction) external override {
        require(auction.maker == msg.sender, "NFTAuctionsFeature::preSignNFTAuction/ONLY_MAKER");
        if (auction.nftKind == NFTKind.ERC721) {
            require(auction.nftTokenAmount == 1, "NFTAuctionsFeature::preSignNFTAuction/INVALID_ERC721_TOKEN_AMOUNT");
        }
        LibNFTAuctionsStorage.getStorage().auctionState[getNFTAuctionHash(auction)].preSigned = true;
        if (auction.auctionKind == NFTAuctionKind.DUTCH) {
            if (auction.nftKind == NFTKind.ERC721) {
                emit ERC721DutchAuctionPreSigned(
                    auction.maker,
                    auction.startTime,
                    auction.endTime,
                    auction.nonce,
                    auction.erc20Token,
                    auction.startErc20TokenAmount,
                    auction.endOrReservedErc20TokenAmount, // as endErc20TokenAmount
                    auction.fees,
                    auction.nftToken,
                    auction.nftTokenId
                );
            } else {
                emit ERC1155DutchAuctionPreSigned(
                    auction.maker,
                    auction.startTime,
                    auction.endTime,
                    auction.nonce,
                    auction.erc20Token,
                    auction.startErc20TokenAmount,
                    auction.endOrReservedErc20TokenAmount, // as endErc20TokenAmount
                    auction.fees,
                    auction.nftToken,
                    auction.nftTokenId,
                    auction.nftTokenAmount
                );
            }
        } else {
            if (auction.nftKind == NFTKind.ERC721) {
                emit ERC721EnglishAuctionPreSigned(
                    auction.earlyMatch,
                    auction.maker,
                    auction.startTime,
                    auction.endTime,
                    auction.nonce,
                    auction.erc20Token,
                    auction.startErc20TokenAmount,
                    auction.endOrReservedErc20TokenAmount, // as reservedErc20TokenAmount
                    auction.fees,
                    auction.nftToken,
                    auction.nftTokenId
                );
            } else {
                emit ERC1155EnglishAuctionPreSigned(
                    auction.earlyMatch,
                    auction.maker,
                    auction.startTime,
                    auction.endTime,
                    auction.nonce,
                    auction.erc20Token,
                    auction.startErc20TokenAmount,
                    auction.endOrReservedErc20TokenAmount, // as reservedErc20TokenAmount
                    auction.fees,
                    auction.nftToken,
                    auction.nftTokenId,
                    auction.nftTokenAmount
                );
            }
        }
    }

    function _validateSender(address taker, EnglishAuctionBid memory enBid) internal pure returns(bool) {
        if (taker == enBid.auction.maker) {
            return true;
        } else if (enBid.erc20TokenAmount >= enBid.auction.endOrReservedErc20TokenAmount) { // as reservedErc20TokenAmount
            for (uint256 i = 0; i < enBid.auction.fees.length; ++i) {
                if (enBid.auction.fees[i].recipient == taker && enBid.auction.fees[i].isMatcher) {
                    return true;
                }
            }
        }
        return false;
    }

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
        EnglishAuctionBid memory enBid,
        LibSignature.Signature memory auctionSig,
        LibSignature.Signature memory bidSig,
        bool unwrapNativeToken,
        bytes memory takerCallbackData
    ) external override {
        _acceptBid(enBid.auction.maker, msg.sender, enBid, auctionSig, bidSig, unwrapNativeToken, takerCallbackData);
    }

    function _acceptBid(
        address nftOwner,
        address taker,
        EnglishAuctionBid memory enBid,
        LibSignature.Signature memory auctionSig,
        LibSignature.Signature memory bidSig,
        bool unwrapNativeToken,
        bytes memory takerCallbackData
    ) private {
        require(enBid.auction.auctionKind == NFTAuctionKind.ENGLISH, "NFTAuctionsFeature::acceptBid/AUCTION_KIND_NOT_ENGLISH");
        require(enBid.erc20TokenAmount >= enBid.auction.startErc20TokenAmount, "NFTAuctionsFeature::acceptBid/PRICE_TOO_LOW");
        require(_validateSender(taker, enBid), "NFTAuctionsFeature::acceptBid/NO_PERMISSION_TO_TAKE");

        NFTAuctionInfo memory auctionInfo = getNFTAuctionInfo(enBid.auction);

        // check the signature for the English bid.
        _validateEnAuctionBidSignature(auctionInfo.auctionStructHash, enBid, bidSig);

        // Check that the auction can be filled.
        _validateNFTAuction(enBid.auction, auctionSig, auctionInfo, enBid.auction.nftTokenAmount);

        _updateAuctionState(enBid.auction.maker, enBid.auction.nonce, auctionInfo.auctionHash, auctionInfo.remainingAmount, enBid.auction.nftTokenAmount);

        if (unwrapNativeToken) {
            // The ERC20 token must be WETH for it to be unwrapped.
            if (enBid.auction.erc20Token != WETH) {
                LibNFTOrdersRichErrors.ERC20TokenMismatchError(
                    address(enBid.auction.erc20Token),
                    address(WETH)
                ).rrevert();
            }
            // Transfer the WETH from the maker to the Exchange Proxy
            // so we can unwrap it before sending it to the seller.
            // TODO: Probably safe to just use WETH.transferFrom for some
            //       small gas savings
            _transferERC20TokensFrom(
                WETH,
                enBid.bidMaker,
                address(this),
                enBid.erc20TokenAmount
            );
            // Unwrap WETH into ETH.
            WETH.withdraw(enBid.erc20TokenAmount);
            // Send ETH to the seller.
            _transferEth(payable(enBid.auction.maker), enBid.erc20TokenAmount);
        } else {
            // Transfer the ERC20 token from the buyer to the seller.
            _transferERC20TokensFrom(
                enBid.auction.erc20Token,
                enBid.bidMaker,
                enBid.auction.maker,
                enBid.erc20TokenAmount
            );
        }

        if (takerCallbackData.length > 0) {
            require(taker != address(this), "NFTAuctionsFeature::_acceptBid/CANNOT_CALLBACK_SELF");
            // Invoke the callback
            bytes4 callbackResult = ITakerCallback(taker).zeroExTakerCallback(auctionInfo.auctionHash, takerCallbackData);
            // Check for the magic success bytes
            require(callbackResult == TAKER_CALLBACK_MAGIC_BYTES, "NFTAuctionsFeature::_acceptBid/CALLBACK_FAILED");
        }

        if (enBid.auction.nftKind == NFTKind.ERC721) {
            _transferERC721AssetFrom(IERC721Token(enBid.auction.nftToken), nftOwner, enBid.bidMaker, enBid.auction.nftTokenId);
        } else {
            _transferERC1155AssetFrom(IERC1155Token(enBid.auction.nftToken), nftOwner, enBid.bidMaker, enBid.auction.nftTokenId, enBid.auction.nftTokenAmount);
        }

        {
            uint256 len = enBid.auction.fees.length;
            for (uint256 i = 0; i < len; ++i) {
                if (enBid.auction.fees[i].isMatcher && enBid.auction.fees[i].recipient != taker) {
                    enBid.auction.fees[i].amountOrRate = 0; // as rate with precision `1 ether`
                }
            }
        }

        _payFees(
            enBid.auction,
            enBid.bidMaker,
            enBid.erc20TokenAmount,
            false
        );

        _emitEnglishAuctionFilled(enBid, taker);
    }

    function _emitEnglishAuctionFilled(EnglishAuctionBid memory enBid, address taker) private {
        emit EnglishAuctionFilled(
            enBid.auction.nftKind,
            enBid.auction.earlyMatch,
            enBid.auction.maker,
            enBid.bidMaker,
            taker,
            enBid.auction.nonce,
            enBid.auction.erc20Token,
            enBid.erc20TokenAmount,
            enBid.auction.nftToken,
            enBid.auction.nftTokenId,
            enBid.auction.nftTokenAmount
        );
    }

    function _onNFTReceived(        
        address operator,
        address /*from*/,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) private {
        (
            uint256 c,
            EnglishAuctionBid memory enBid,
            LibSignature.Signature memory auctionSig,
            LibSignature.Signature memory bidSig,
            bool unwrapNativeToken
        ) = abi.decode(
            data,
            (uint256, EnglishAuctionBid, LibSignature.Signature, LibSignature.Signature, bool)
        );c;
        require(enBid.auction.nftTokenId == tokenId, "NFTAuctionsFeature::_onNFTReceived/TOKEN_ID_MISMATCH");
        require(enBid.auction.nftTokenAmount == value, "NFTAuctionsFeature::_onNFTReceived/TOKEN_AMOUNT_MISMATCH");
        if (msg.sender != enBid.auction.nftToken) {
            if (enBid.auction.nftKind == NFTKind.ERC721) {
                LibNFTOrdersRichErrors.ERC721TokenMismatchError(msg.sender, address(enBid.auction.nftToken)).rrevert();
            } else {
                LibNFTOrdersRichErrors.ERC1155TokenMismatchError(msg.sender, address(enBid.auction.nftToken)).rrevert();
            }
        }
        _acceptBid(address(this), operator, enBid, auctionSig, bidSig, unwrapNativeToken, new bytes(0));
    }

    function onERC721Received(address operator, address from, uint256 tokenId,
        bytes calldata data) external returns (bytes4) 
    {
        (uint256 code) = abi.decode(data[:32], (uint256));
        if (code == CODE_ERC721) {
             (bool success, bytes memory resultData) = address(this).delegatecall(
                abi.encodeWithSelector(
                    IOnNFTReceived.onERC721Received2.selector,
                    operator, from, tokenId, data
                )
            );
            if (!success) {
                _revertWithData(resultData);
            }
            _returnWithData(resultData);
        } else if (code == CODE_AUCTION) {
            _onNFTReceived(operator,from,tokenId,1,data);
            return this.onERC721Received.selector;
        }
        revert("NFTAuctionsFeature::onERC721Received/UNKNOWN_CODE");
    }

    function onERC1155Received(address operator, address from, uint256 tokenId, 
        uint256 value, bytes calldata data) external returns (bytes4)
    {
        (uint256 code) = abi.decode(data[:32], (uint256));
        if (code == CODE_ERC1155) {
            (bool success, bytes memory resultData) = address(this).delegatecall(
                abi.encodeWithSelector(
                    IOnNFTReceived.onERC1155Received2.selector,
                    operator, from, tokenId, value, data
                )
            );
            if (!success) {
                _revertWithData(resultData);
            }
            _returnWithData(resultData);
        } else if (code == CODE_AUCTION) {
            _onNFTReceived(operator,from,tokenId,value,data);
            return this.onERC1155Received.selector;
        }
        revert("NFTAuctionsFeature::onERC1155Received/UNKNOWN_CODE");
    }

    /// @dev Revert with arbitrary bytes.
    /// @param data Revert data.
    function _revertWithData(bytes memory data) private pure {
        assembly { revert(add(data, 32), mload(data)) }
    }

    /// @dev Return with arbitrary bytes.
    /// @param data Return data.
    function _returnWithData(bytes memory data) private pure {
        assembly { return(add(data, 32), mload(data)) }
    }
}
