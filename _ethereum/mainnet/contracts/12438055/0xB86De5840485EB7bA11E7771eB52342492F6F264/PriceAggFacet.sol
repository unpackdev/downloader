// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import "./SafeCast.sol";
import "./ChainlinkLib.sol";
import "./CompoundLib.sol";

// Interfaces
import "./AggregatorV2V3Interface.sol";
import "./ERC20.sol";

// Storage
import "./app.sol";

contract PriceAggFacet {
    uint256 internal constant TEN = 10;

    /**
     * @notice It returns the price of the token pair as given from the Chainlink Aggregator.
     * @dev It tries to use ETH as a pass through asset if the direct pair is not supported.
     * @param src Source token address.
     * @param dst Destination token address.
     * @return int256 The latest answer as given from Chainlink.
     */
    function getPriceFor(address src, address dst)
        external
        view
        returns (int256)
    {
        return _priceFor(src, dst);
    }

    /**
     * @notice It calculates the value of a token amount into another.
     * @param src Source token address.
     * @param dst Destination token address.
     * @param srcAmount Amount of the source token to convert into the destination token.
     * @return uint256 Value of the source token amount in destination tokens.
     */
    function getValueFor(
        address src,
        address dst,
        uint256 srcAmount
    ) external view returns (uint256) {
        return _valueFor(src, srcAmount, uint256(_priceFor(src, dst)));
    }

    function _valueFor(
        address src,
        uint256 amount,
        uint256 exchangeRate
    ) internal view returns (uint256) {
        return (amount * exchangeRate) / _oneToken(src);
    }

    function _oneToken(address token) internal view returns (uint256) {
        return TEN**_decimalsFor(token);
    }

    /**
     * @dev It gets the number of decimals for a given token.
     * @param addr Token address to get decimals for.
     * @return uint8 Number of decimals the given token.
     */
    function _decimalsFor(address addr) internal view returns (uint8) {
        return ERC20(addr).decimals();
    }

    /**
     * @dev Tries to calculate a price from Compound and Chainlink.
     */
    function _priceFor(address src, address dst)
        private
        view
        returns (int256 price_)
    {
        // If no Compound route, try Chainlink directly.
        price_ = int256(_compoundPriceFor(src, dst));
        if (price_ == 0) {
            price_ = _chainlinkPriceFor(src, dst);
            if (price_ == 0) {
                revert("Teller: cannot calc price");
            }
        }
    }

    /**
     * @dev Tries to get a price from {src} to {dst} by checking if either tokens are from Compound.
     */
    function _compoundPriceFor(address src, address dst)
        private
        view
        returns (uint256)
    {
        (bool isSrcCompound, address srcUnderlying) = _isCToken(src);
        if (isSrcCompound) {
            uint256 cRate = CompoundLib.valueInUnderlying(src, _oneToken(src));
            if (srcUnderlying == dst) {
                return cRate;
            } else {
                return _calcPriceFromCompoundRate(srcUnderlying, dst, cRate);
            }
        } else {
            (bool isDstCompound, address dstUnderlying) = _isCToken(dst);
            if (isDstCompound) {
                uint256 cRate =
                    CompoundLib.valueOfUnderlying(dst, _oneToken(src));
                if (dstUnderlying == src) {
                    return cRate;
                } else {
                    return
                        _calcPriceFromCompoundRate(src, dstUnderlying, cRate);
                }
            }
        }

        return 0;
    }

    /**
     * @dev Tries to get a price from {src} to {dst} and then converts using a rate from Compound.
     */
    function _calcPriceFromCompoundRate(
        address src,
        address dst,
        uint256 cRate
    ) private view returns (uint256) {
        uint256 rate = uint256(_chainlinkPriceFor(src, dst));
        uint256 value = (cRate * _oneToken(dst)) / rate;
        return _scale(value, _decimalsFor(src), _decimalsFor(dst));
    }

    /**
     * @dev Scales the {value} by the difference in decimal values.
     */
    function _scale(
        uint256 value,
        uint256 srcDecimals,
        uint256 dstDecimals
    ) internal pure returns (uint256) {
        if (dstDecimals > srcDecimals) {
            return value * (TEN**(dstDecimals - srcDecimals));
        } else {
            return value / (TEN**(srcDecimals - dstDecimals));
        }
    }

    /**
     * @dev Tries to calculate the price of {src} in {dst}
     */
    function _chainlinkPriceFor(address src, address dst)
        private
        view
        returns (int256)
    {
        (address agg, bool foundAgg, bool inverse) =
            ChainlinkLib.aggregatorFor(src, dst);
        if (foundAgg) {
            uint256 price =
                SafeCast.toUint256(AggregatorV2V3Interface(agg).latestAnswer());
            uint8 resDecimals = AggregatorV2V3Interface(agg).decimals();
            if (inverse) {
                price = (TEN**(resDecimals + resDecimals)) / price;
            }
            return
                SafeCast.toInt256(
                    (_scale(price, resDecimals, _decimalsFor(dst)))
                );
        } else {
            address WETH = AppStorageLib.store().assetAddresses["WETH"];
            if (dst != WETH) {
                int256 price1 = _priceFor(src, WETH);
                if (price1 > 0) {
                    int256 price2 = _priceFor(dst, WETH);
                    if (price2 > 0) {
                        uint256 dstFactor = TEN**_decimalsFor(dst);
                        return (price1 * int256(dstFactor)) / price2;
                    }
                }
            }
        }

        return 0;
    }

    function _isCToken(address token)
        private
        view
        returns (bool isCToken, address underlying)
    {
        isCToken = CompoundLib.isCompoundToken(token);
        if (isCToken) {
            underlying = CompoundLib.getUnderlying(token);
        }
    }
}
