// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20MetadataUpgradeable.sol";
import "./IUniswapV3Pool.sol";
import "./ICustomOracle.sol";
import "./PriceOracleStorage.sol";
import "./EIP2535Initializable.sol";
import "./IrrigationAccessControl.sol";
import "./Constants.sol";
import "./AggregatorV2V3Interface.sol";
import "./UniswapV3Twap.sol";

contract PriceOracleUpgradeable is EIP2535Initializable, IrrigationAccessControl {
    using PriceOracleStorage for PriceOracleStorage.Layout;
    /// @dev errors
    error StalePrice();
    error InvalidChainLinkPrice();

    /// @dev events
    event UpdateAssetPrice(address asset, uint256 oldPrice, uint256 price);

    event UpdateOracle(address asset, address oracle, address base, OracleType oType);

    event UpdateOracleAddress(address indexed asset, address indexed oracle);

    /// @dev errors
    error InvalidChainlinkFeed();
    error InvalidCustomOracleAddress();

    function getUnderlyingPriceETH() public view returns (uint) {
        /// @dev feed decimals for ether/usd is 8, so multiplier is 10**(18-8)
        return
            getChainlinkPrice(
                AggregatorV2V3Interface(
                    PriceOracleStorage.layout().oracleItems[Constants.ETHER].oracle
                )
            ) * 1e10;
    }

    function getPrice(address asset) public view returns (uint256 price) {
        if (asset == Constants.ETHER || asset == Constants.WETH) {
            price = getUnderlyingPriceETH();
            return price;
        }
        OracleItem memory oracleItem = PriceOracleStorage.layout().oracleItems[asset];
        if (oracleItem.oType == OracleType.DIRECT) {
            price = oracleItem.price;
        } else if (oracleItem.oType == OracleType.CHAINLINK) {
            price =
                getChainlinkPrice(AggregatorV2V3Interface(oracleItem.oracle)) *
                oracleItem.multiplier;
        } else if (oracleItem.oType == OracleType.CUSTOM_ORACLE) {
            price = ICustomOracle(oracleItem.oracle).latestPrice();
        } else {
            price = getUniswapV3Price(asset, oracleItem);
        }
        if (oracleItem.base != address(0))
            price = (price * getPrice(oracleItem.base)) / Constants.D18;
    }

    function getWaterPrice() external view returns (uint256) {
        return getPrice(address(this));
    }

    /// @dev returns chainlink price
    function getChainlinkPrice(AggregatorV2V3Interface feed) internal view returns (uint256) {
        (uint80 roundId, int256 answer, , uint256 updatedAt, ) = feed.latestRoundData();
        if (answer == 0 || roundId == 0) revert InvalidChainLinkPrice();
        if (block.timestamp > updatedAt + Constants.GRACE_PERIOD_TIME) revert StalePrice();
        return uint256(answer);
    }

    function getUniswapV3Price(
        address asset,
        OracleItem memory oracleItem
    ) internal view returns (uint256) {
        /// @dev if multiplier is greater than 10**18, uniswap library math function reverts with error.
        if (oracleItem.multiplier > Constants.D18)
            return
                UniswapV3Twap.getTwap(Constants.D18, asset, oracleItem.oracle, 10) *
                (oracleItem.multiplier / Constants.D18);
        else return UniswapV3Twap.getTwap(oracleItem.multiplier, asset, oracleItem.oracle, 10);
    }

    /// @dev admin setters
    /// @dev direct price
    function setDirectPrice(address asset, uint256 price) external onlyAdminRole {
        PriceOracleStorage.layout().oracleItems[asset].price = price;
        emit UpdateAssetPrice(asset, PriceOracleStorage.layout().oracleItems[asset].price, price);
    }

    /// @dev update oracle into any type
    function setOracle(
        address asset,
        address oracle,
        address base,
        OracleType oType
    ) external onlyAdminRole {
        uint256 multiplier = Constants.D18;
        if (oType == OracleType.CHAINLINK) {
            multiplier = 10 ** (uint256(18) - AggregatorV2V3Interface(oracle).decimals());
        } else if (oType == OracleType.UNISWAP_V3) {
            address token0 = IUniswapV3Pool(oracle).token0();
            address token1 = IUniswapV3Pool(oracle).token1();
            uint256 decimals0 = IERC20MetadataUpgradeable(token0).decimals();
            uint256 decimals1 = IERC20MetadataUpgradeable(token1).decimals();
            if (asset == token0) multiplier = 10 ** (18 - decimals1 + decimals0);
            else multiplier = 10 ** (18 - decimals0 + decimals1);
        }
        OracleItem memory oracleItem = OracleItem(0, multiplier, oracle, base, oType);
        PriceOracleStorage.layout().oracleItems[asset] = oracleItem;
        emit UpdateOracle(asset, oracle, base, oType);
    }

    // update only oracle address to reduce gas
    function setOracleAddress(address asset, address oracle) external onlyAdminRole {
        PriceOracleStorage.layout().oracleItems[asset].oracle = oracle;
        emit UpdateOracleAddress(asset, oracle);
    }

    function getOracleItem(address asset) external view returns (OracleItem memory) {
        return PriceOracleStorage.layout().oracleItems[asset];
    }
}
