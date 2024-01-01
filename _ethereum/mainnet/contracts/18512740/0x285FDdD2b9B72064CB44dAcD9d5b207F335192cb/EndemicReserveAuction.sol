// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ECDSA.sol";

import "./EndemicExchangeCore.sol";
import "./EndemicFundsDistributor.sol";
import "./EndemicEIP712.sol";
import "./EndemicNonceManager.sol";

abstract contract EndemicReserveAuction is
    EndemicFundsDistributor,
    EndemicExchangeCore,
    EndemicEIP712,
    EndemicNonceManager
{
    using ECDSA for bytes32;

    bytes32 private constant RESERVE_AUCTION_TYPEHASH =
        keccak256(
            "ReserveAuction(uint256 orderNonce,address nftContract,uint256 tokenId,address paymentErc20TokenAddress,uint256 price,bool isBid)"
        );

    bytes32 private constant RESERVE_AUCTION_APPROVAL_TYPEHASH =
        keccak256(
            "ReserveAuctionApproval(address auctionSigner,address bidSigner,uint256 auctionNonce,uint256 bidNonce,address nftContract,uint256 tokenId,address paymentErc20TokenAddress,uint256 auctionPrice,uint256 bidPrice)"
        );

    struct ReserveAuction {
        address signer;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 orderNonce;
        address nftContract;
        uint256 tokenId;
        address paymentErc20TokenAddress;
        uint256 price;
        bool isBid;
    }

    struct AuctionFees {
        uint256 bidPrice;
        uint256 takerFee;
        uint256 takerCut;
        uint256 makerCut;
        uint256 totalCut;
        uint256 royaltieFee;
        address royaltiesRecipient;
    }

    function finalizeReserveAuction(
        uint8 v,
        bytes32 r,
        bytes32 s,
        ReserveAuction calldata auction,
        ReserveAuction calldata bid
    ) external onlySupportedERC20Payments(auction.paymentErc20TokenAddress) {
        if (
            auction.isBid ||
            !bid.isBid ||
            auction.nftContract != bid.nftContract ||
            auction.tokenId != bid.tokenId ||
            auction.paymentErc20TokenAddress != bid.paymentErc20TokenAddress ||
            auction.signer == bid.signer
        ) revert InvalidConfiguration();

        _verifyApprovalSignature(v, r, s, auction, bid);
        _verifySignature(auction);
        _verifySignature(bid);

        AuctionFees memory auctionFees = _calculateAuctionFees(auction, bid);

        if (auction.price + auctionFees.takerCut > bid.price) {
            revert UnsufficientCurrencySupplied();
        }

        _invalidateNonce(auction.signer, auction.orderNonce);
        _invalidateNonce(bid.signer, bid.orderNonce);

        IERC721(auction.nftContract).transferFrom(
            auction.signer,
            bid.signer,
            auction.tokenId
        );

        _distributeFunds(
            auctionFees.bidPrice,
            auctionFees.makerCut,
            auctionFees.totalCut,
            auctionFees.royaltieFee,
            auctionFees.royaltiesRecipient,
            auction.signer,
            bid.signer,
            auction.paymentErc20TokenAddress
        );

        emit AuctionSuccessful(
            auction.nftContract,
            auction.tokenId,
            auctionFees.bidPrice,
            auction.signer,
            bid.signer,
            auctionFees.totalCut,
            auction.paymentErc20TokenAddress
        );
    }

    function _calculateAuctionFees(
        ReserveAuction calldata auction,
        ReserveAuction calldata bid
    ) internal view returns (AuctionFees memory data) {
        (data.takerFee, ) = paymentManager.getPaymentMethodFees(
            auction.paymentErc20TokenAddress
        );
        data.bidPrice = (bid.price * MAX_FEE) / (data.takerFee + MAX_FEE);
        data.takerCut = _calculateCut(data.takerFee, auction.price);

        (
            data.makerCut,
            ,
            data.royaltiesRecipient,
            data.royaltieFee,
            data.totalCut
        ) = _calculateFees(
            auction.paymentErc20TokenAddress,
            auction.nftContract,
            auction.tokenId,
            data.bidPrice
        );
    }

    function _verifySignature(ReserveAuction calldata data) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _buildDomainSeparator(),
                keccak256(
                    abi.encode(
                        RESERVE_AUCTION_TYPEHASH,
                        data.orderNonce,
                        data.nftContract,
                        data.tokenId,
                        data.paymentErc20TokenAddress,
                        data.price,
                        data.isBid
                    )
                )
            )
        );

        if (digest.recover(data.v, data.r, data.s) != data.signer) {
            revert InvalidSignature();
        }
    }

    function _verifyApprovalSignature(
        uint8 v,
        bytes32 r,
        bytes32 s,
        ReserveAuction calldata auction,
        ReserveAuction calldata bid
    ) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _buildDomainSeparator(),
                keccak256(
                    abi.encode(
                        RESERVE_AUCTION_APPROVAL_TYPEHASH,
                        auction.signer,
                        bid.signer,
                        auction.orderNonce,
                        bid.orderNonce,
                        auction.nftContract,
                        auction.tokenId,
                        auction.paymentErc20TokenAddress,
                        auction.price,
                        bid.price
                    )
                )
            )
        );

        if (digest.recover(v, r, s) != approvedSigner) {
            revert InvalidSignature();
        }
    }

    /**
     * @notice See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[500] private __gap;
}
