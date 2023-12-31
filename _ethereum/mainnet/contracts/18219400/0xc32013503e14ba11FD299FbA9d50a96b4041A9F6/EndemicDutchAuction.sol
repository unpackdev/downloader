// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ReentrancyGuardUpgradeable.sol";
import "./ECDSA.sol";

import "./EndemicExchangeCore.sol";
import "./EndemicFundsDistributor.sol";
import "./EndemicEIP712.sol";
import "./EndemicNonceManager.sol";

abstract contract EndemicDutchAuction is
    ReentrancyGuardUpgradeable,
    EndemicFundsDistributor,
    EndemicExchangeCore,
    EndemicEIP712,
    EndemicNonceManager
{
    using ECDSA for bytes32;

    bytes32 private constant AUCTION_TYPEHASH =
        keccak256(
            "DutchAuction(uint256 orderNonce,address nftContract,uint256 tokenId,address paymentErc20TokenAddress,uint256 startingPrice,uint256 endingPrice,uint256 startingAt,uint256 duration)"
        );

    struct DutchAuction {
        address seller;
        uint256 orderNonce;
        address nftContract;
        uint256 tokenId;
        address paymentErc20TokenAddress;
        uint256 startingPrice;
        uint256 endingPrice;
        uint256 startingAt;
        uint256 duration;
    }

    function bidForDutchAuction(
        uint8 v,
        bytes32 r,
        bytes32 s,
        DutchAuction calldata auction
    ) external payable nonReentrant {
        if (block.timestamp < auction.startingAt) revert AuctionNotStarted();
        if (auction.seller == msg.sender) revert InvalidCaller();
        if (auction.startingPrice <= auction.endingPrice) {
            revert InvalidConfiguration();
        }
        if (auction.duration == 0) {
            revert InvalidDuration();
        }

        _verifySignature(auction, v, r, s);

        _requireSupportedPaymentMethod(auction.paymentErc20TokenAddress);

        _invalidateNonce(auction.seller, auction.orderNonce);

        uint256 currentPrice = _calculateCurrentPrice(
            auction.startingPrice,
            auction.endingPrice,
            auction.startingAt,
            auction.duration
        );

        if (currentPrice == 0) revert InvalidPrice();

        (
            uint256 makerCut,
            uint256 takerCut,
            address royaltiesRecipient,
            uint256 royaltieFee,
            uint256 totalCut
        ) = _calculateFees(
                auction.paymentErc20TokenAddress,
                auction.nftContract,
                auction.tokenId,
                currentPrice
            );

        currentPrice = _determinePriceByPaymentMethod(
            auction.paymentErc20TokenAddress,
            currentPrice,
            takerCut
        );

        _requireSufficientCurrencySupplied(
            currentPrice + takerCut,
            auction.paymentErc20TokenAddress,
            msg.sender
        );

        IERC721(auction.nftContract).transferFrom(
            auction.seller,
            msg.sender,
            auction.tokenId
        );

        _distributeFunds(
            currentPrice,
            makerCut,
            totalCut,
            royaltieFee,
            royaltiesRecipient,
            auction.seller,
            msg.sender,
            auction.paymentErc20TokenAddress
        );

        emit AuctionSuccessful(
            auction.nftContract,
            auction.tokenId,
            currentPrice,
            auction.seller,
            msg.sender,
            totalCut
        );
    }

    function getCurrentPrice(
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 startingAt,
        uint256 duration
    ) external view returns (uint256) {
        return
            _calculateCurrentPrice(
                startingPrice,
                endingPrice,
                startingAt,
                duration
            );
    }

    function _determinePriceByPaymentMethod(
        address paymentErc20TokenAddress,
        uint256 currentPriceWithoutFees,
        uint256 takerCut
    ) internal view returns (uint256) {
        //if auction is in ERC20 we use price calculated in moment of method execution
        if (paymentErc20TokenAddress != ZERO_ADDRESS) {
            return currentPriceWithoutFees;
        }

        //auction is in ether so we use amount of supplied ethers without taker cut as auction price
        uint256 suppliedEtherWithoutFees = msg.value - takerCut;

        //amount of supplied ether without buyer fees must not be smaller than the current price without buyer fees
        if (suppliedEtherWithoutFees < currentPriceWithoutFees) {
            revert UnsufficientCurrencySupplied();
        }

        return suppliedEtherWithoutFees;
    }

    function _calculateCurrentPrice(
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 startingAt,
        uint256 duration
    ) internal view returns (uint256) {
        uint256 secondsPassed = 0;

        if (block.timestamp > startingAt) {
            secondsPassed = block.timestamp - startingAt;
        }

        // NOTE: We don't use SafeMath (or similar) in this function because
        //  all of our public functions carefully cap the maximum values for
        //  time (at 64-bits) and currency (at 128-bits). _duration is
        //  also known to be non-zero (see the require() statement in
        //  _addAuction())
        if (secondsPassed >= duration) {
            // We've reached the end of the dynamic pricing portion
            // of the auction, just return the end price.
            return endingPrice;
        } else {
            // Starting price can be higher than ending price (and often is!), so
            // this delta can be negative.
            int256 totalPriceChange = int256(endingPrice) -
                int256(startingPrice);

            // This multiplication can't overflow, _secondsPassed will easily fit within
            // 64-bits, and totalPriceChange will easily fit within 128-bits, their product
            // will always fit within 256-bits.
            int256 currentPriceChange = (totalPriceChange *
                int256(secondsPassed)) / int256(duration);

            // currentPriceChange can be negative, but if so, will have a magnitude
            // less that _startingPrice. Thus, this result will always end up positive.
            return uint256(int256(startingPrice) + currentPriceChange);
        }
    }

    function _verifySignature(
        DutchAuction calldata auction,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _buildDomainSeparator(),
                keccak256(
                    abi.encode(
                        AUCTION_TYPEHASH,
                        auction.orderNonce,
                        auction.nftContract,
                        auction.tokenId,
                        auction.paymentErc20TokenAddress,
                        auction.startingPrice,
                        auction.endingPrice,
                        auction.startingAt,
                        auction.duration
                    )
                )
            )
        );

        if (digest.recover(v, r, s) != auction.seller) {
            revert InvalidSignature();
        }
    }

    /**
     * @notice See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}
