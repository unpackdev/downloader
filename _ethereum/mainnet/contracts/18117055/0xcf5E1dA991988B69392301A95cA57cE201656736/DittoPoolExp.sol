// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./Fee.sol";
import "./NftCostData.sol";
import "./IDittoPool.sol";
import "./DittoPool.sol";
import "./CurveErrorCode.sol";
import "./FixedPointMathLib.sol";
import "./DittoPoolTrade.sol";

/**
 * @dev NOTE: we assume delta is > 1, as checked by validateDelta()
 */
contract DittoPoolExp is DittoPool {
    using FixedPointMathLib for uint256;

    ///@inheritdoc IDittoPool
    function bondingCurve() public pure virtual override (IDittoPool) returns (string memory curve) {
        return "Curve: EXP";
    }

    // minimum price to prevent numerical issues
    uint256 public constant MIN_PRICE = 1 gwei;

    /**
     * @dev See {DittPool-_validateDelta}
     */
    function _invalidDelta(uint128 delta) internal pure override returns (bool valid) {
        return delta <= FixedPointMathLib.WAD;
    }

    /**
     * @dev See {DittPool-_validateBasePrice}
     */
    function _invalidBasePrice(uint128 newBasePrice) internal pure override returns (bool) {
        return newBasePrice < MIN_PRICE;
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
        // NOTE: we assume delta is > 1, as checked by validateDelta()
        // We only calculate changes for buying 1 or more NFTs
        if (numItems == 0) {
            return (CurveErrorCode.INVALID_NUMITEMS, 0, 0, 0, nftCostData);
        }

        uint256 deltaPowN = uint256(delta).fpow(numItems, FixedPointMathLib.WAD);

        // For an exponential curve, the base price is multiplied by delta for each item bought
        uint256 newBasePrice_ = uint256(basePrice).fmul(deltaPowN, FixedPointMathLib.WAD);
        if (newBasePrice_ > type(uint128).max) {
            return (CurveErrorCode.BASE_PRICE_OVERFLOW, 0, 0, 0, nftCostData);
        }
        newBasePrice = uint128(newBasePrice_);

        // Spot price is assumed to be the instant sell price. To avoid arbitraging LPs, we adjust the buy price upwards.
        // If base price for buy and sell were the same, then someone could buy 1 NFT and then sell for immediate profit.
        // EX: Let S be base price. Then buying 1 NFT costs S ETH, now new base price is (S * delta).
        // The same person could then sell for (S * delta) ETH, netting them delta ETH profit.
        // If base price for buy and sell differ by delta, then buying costs (S * delta) ETH.
        // The new base price would become (S * delta), so selling would also yield (S * delta) ETH.
        uint256 buyBasePrice = _mul(basePrice, delta);

        // If the user buys n items, then the total cost is equal to:
        // buyBasePrice + (delta * buyBasePrice) + (delta^2 * buyBasePrice) + ... (delta^(numItems - 1) * buyBasePrice)
        // This is equal to buyBasePrice * (delta^n - 1) / (delta - 1)
        inputValue = buyBasePrice.fmul(
            (deltaPowN - FixedPointMathLib.WAD).fdiv(
                delta - FixedPointMathLib.WAD, FixedPointMathLib.WAD
            ),
            FixedPointMathLib.WAD
        );

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
        // NOTE: we assume delta is > 1, as checked by validateDelta()

        // We only calculate changes for buying 1 or more NFTs
        if (numItems == 0) {
            return (CurveErrorCode.INVALID_NUMITEMS, 0, 0, 0, nftCostData);
        }

        uint256 invDelta = FixedPointMathLib.WAD.fdiv(delta, FixedPointMathLib.WAD);
        uint256 invDeltaPowN = invDelta.fpow(numItems, FixedPointMathLib.WAD);

        // For an exponential curve, the base price is divided by delta for each item sold
        // safe to convert newBasePrice directly into uint128 since we know newBasePrice <= basePrice
        // and basePrice <= type(uint128).max
        newBasePrice = uint128(uint256(basePrice).fmul(invDeltaPowN, FixedPointMathLib.WAD));
        if (newBasePrice < MIN_PRICE) {
            newBasePrice = uint128(MIN_PRICE);
        }

        // If the user sells n items, then the total revenue is equal to:
        // basePrice + ((1 / delta) * basePrice) + ((1 / delta)^2 * basePrice) + ... ((1 / delta)^(numItems - 1) * basePrice)
        // This is equal to basePrice * (1 - (1 / delta^n)) / (1 - (1 / delta))
        outputValue = uint256(basePrice).fmul(
            (FixedPointMathLib.WAD - invDeltaPowN).fdiv(
                FixedPointMathLib.WAD - invDelta, FixedPointMathLib.WAD
            ),
            FixedPointMathLib.WAD
        );

        uint256 totalFees;
        (totalFees, nftCostData) = _calculateUniformNftCostData(outputValue, numItems, fee_);

        outputValue -= totalFees;

        // Keep delta the same
        newDelta = delta;

        // If we got all the way here, no math error happened
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
