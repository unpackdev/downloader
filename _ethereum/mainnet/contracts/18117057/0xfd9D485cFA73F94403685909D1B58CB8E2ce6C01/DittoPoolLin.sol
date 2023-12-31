// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./Fee.sol";
import "./NftCostData.sol";
import "./IDittoPool.sol";
import "./DittoPool.sol";
import "./CurveErrorCode.sol";
import "./DittoPoolTrade.sol";

contract DittoPoolLin is DittoPool {
    
    ///@inheritdoc IDittoPool
    function bondingCurve() public pure virtual override (IDittoPool) returns (string memory curve) {
        return "Curve: LIN";
    }

    /**
     * @dev See {DittPool-_validateDelta}
     */
    function _invalidDelta(uint128 /*delta*/ ) internal pure override returns (bool valid) {
        // For a linear curve, all values of delta are valid
        return false;
    }

    /**
     * @dev See {DittPool-_validateBasePrice}
     */
    function _invalidBasePrice(uint128 newBasePrice)
        internal
        pure
        override
        returns (bool)
    {
        // For a linear curve, all values of base price are valid
        return newBasePrice == 0;
    }

    /**
     * @dev See {DittPool-_getBuyInfo}
     */
    function _getBuyInfo(
        uint128 basePrice,
        uint128 delta,
        uint256 numItems,
        bytes calldata /*swapData*/,
        Fee memory fee_
    )
        internal
        pure
        virtual
        override
        returns (
            CurveErrorCode error,
            uint128 newBasePrice,
            uint128 newDelta,
            uint256 inputValue,
            NftCostData[] memory nftCostData
        )
    {
        // We only calculate changes for buying 1 or more NFTs
        if (numItems == 0) {
            return (CurveErrorCode.INVALID_NUMITEMS, 0, 0, 0, nftCostData);
        }

        // For a linear curve, the base price increases by delta for each item bought
        uint256 newBasePrice_ = basePrice + delta * numItems;
        if (newBasePrice_ > type(uint128).max) {
            return (CurveErrorCode.BASE_PRICE_OVERFLOW, 0, 0, 0, nftCostData);
        }
        newBasePrice = uint128(newBasePrice_);

        // Spot price is assumed to be the instant sell price. To avoid arbitraging LPs, we adjust the buy price upwards.
        // If base price for buy and sell were the same, then someone could buy 1 NFT and then sell for immediate profit.
        // EX: Let S be base price. Then buying 1 NFT costs S ETH, now new base price is (S+delta).
        // The same person could then sell for (S+delta) ETH, netting them delta ETH profit.
        // If base price for buy and sell differ by delta, then buying costs (S+delta) ETH.
        // The new base price would become (S+delta), so selling would also yield (S+delta) ETH.
        uint256 buyBasePrice = basePrice + delta;

        // If we buy n items, then the total cost is equal to:
        // (buy base price) + (buy base price + 1*delta) + (buy base price + 2*delta) + ... + (buy base price + (n-1)*delta)
        // This is equal to n*(buy base price) + (delta)*(n*(n-1))/2
        // because we have n instances of buy base price, and then we sum up from delta to (n-1)*delta
        inputValue = numItems * buyBasePrice + (numItems * (numItems - 1) * delta) / 2;
        
        uint256 totalFees;
        (totalFees, nftCostData) = _calculateUniformNftCostData(inputValue, numItems, fee_);

        inputValue += totalFees;

        // Keep delta the same
        newDelta = delta;

        // If we got all the way here, no math error happened
        error = CurveErrorCode.OK;
    }

    /**
     *  @dev See {DittPool-_getSellInfo}
     */
    function _getSellInfo(
        uint128 basePrice,
        uint128 delta,
        uint256 numItems,
        bytes calldata /*swapData_*/,
        Fee memory fee_
    )
        internal
        pure
        virtual
        override
        returns (
            CurveErrorCode error,
            uint128 newBasePrice,
            uint128 newDelta,
            uint256 outputValue,
            NftCostData[] memory nftCostData
        )
    {
        // We only calculate changes for selling 1 or more NFTs
        if (numItems == 0) {
            return (CurveErrorCode.INVALID_NUMITEMS, 0, 0, 0, nftCostData);
        }

        // We first calculate the change in base price after selling all of the items
        uint256 totalPriceDecrease = delta * numItems;

        // If the current base price is less than the total amount that the base price should change by...
        if (basePrice < totalPriceDecrease) {
            return (CurveErrorCode.INVALID_NUMITEMS, 0, 0, 0, nftCostData);
        }
        // Otherwise, the current base price is greater than or equal to the total amount that the base price changes
        // Thus we don't need to calculate the maximum number of items until we reach zero base price, so we don't modify numItems

        // The new base price is just the change between base price and the total price change
        newBasePrice = basePrice - uint128(totalPriceDecrease);

        // If we sell n items, then the total sale amount is:
        // (base price) + (base price - 1*delta) + (base price - 2*delta) + ... + (base price - (n-1)*delta)
        // This is equal to n*(base price) - (delta)*(n*(n-1))/2
        outputValue = numItems * basePrice - (numItems * (numItems - 1) * delta) / 2;

        uint256 totalFees;
        (totalFees, nftCostData) = _calculateUniformNftCostData(outputValue, numItems, fee_);

        outputValue -= totalFees;

        // Keep delta the same
        newDelta = delta;

        // If we reached here, no math errors
        error = CurveErrorCode.OK;
    }

    ///@inheritdoc IDittoPool
    function getBuyNftQuote(uint256 numNfts_, bytes calldata swapData_)
        external
        view
        override(IDittoPool, DittoPoolTrade)
        returns (
            CurveErrorCode error,
            uint256 newBasePrice,
            uint256 newDelta,
            uint256 inputAmount,
            NftCostData[] memory nftCostData
        )
    {
        (error, newBasePrice, newDelta, inputAmount, nftCostData) = _getBuyInfo(
            _basePrice,
            _delta,
            numNfts_,
            swapData_,
            Fee({lp: _feeLp, admin: _feeAdmin, protocol: _dittoPoolFactory.getProtocolFee()})
        );
    }

    ///@inheritdoc IDittoPool
    function getSellNftQuote(uint256 numNfts_, bytes calldata swapData_)
        external
        view
        override(IDittoPool, DittoPoolTrade)
        returns (
            CurveErrorCode error,
            uint256 newBasePrice,
            uint256 newDelta,
            uint256 outputAmount,
            NftCostData[] memory nftCostData
        )
    {
        (error, newBasePrice, newDelta, outputAmount, nftCostData) =
        _getSellInfo(
            _basePrice,
            _delta,
            numNfts_,
            swapData_,
            Fee({lp: _feeLp, admin: _feeAdmin, protocol: _dittoPoolFactory.getProtocolFee()})
        );
    }
}
