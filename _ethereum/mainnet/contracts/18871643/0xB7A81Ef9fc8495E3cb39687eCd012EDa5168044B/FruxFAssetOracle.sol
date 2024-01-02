// SPDX-License-Identifier: ISC
pragma solidity ^0.8.21;

import "./AggregatorV3Interface.sol";
import "./IERC20Metadata.sol";

/// @title FruxFAssetOracle
/// @author Jason (Sturdy) https://github.com/iris112
/// @notice  An oracle for CrvUSD/CRV

interface IFAsset {
    function exchangeRateStored() external view returns (uint256);
}

contract FruxFAssetOracle {    
    uint8 public constant DECIMALS = 18;

    address public immutable FASSET;
    address public immutable UNDERLYING_FASSET;
    address public immutable ASSET;
    address public immutable CHAINLINK_MULTIPLY_ADDRESS;
    address public immutable CHAINLINK_DIVIDE_ADDRESS;
    uint256 public immutable CHAINLINK_NORMALIZATION;
    uint256 public immutable MAX_ORACLE_DELAY;
    uint256 public immutable PRICE_MIN;
    
    string public name;

    error CHAINLINK_BAD_PRICE();
    constructor(
        address _fAsset,
        address _underlyingFAsset,
        address _asset,
        address _chainlinkMultiplyAddress,
        address _chainlinkDivideAddress,
        uint256 _maxOracleDelay,
        uint256 _priceMin,
        string memory _name
    ) {
        FASSET = _fAsset;
        UNDERLYING_FASSET = _underlyingFAsset;
        ASSET = _asset;
        CHAINLINK_MULTIPLY_ADDRESS = _chainlinkMultiplyAddress;
        CHAINLINK_DIVIDE_ADDRESS = _chainlinkDivideAddress;

        uint8 _multiplyDecimals = _chainlinkMultiplyAddress != address(0)
            ? AggregatorV3Interface(_chainlinkMultiplyAddress).decimals()
            : 0;
        uint8 _divideDecimals = _chainlinkDivideAddress != address(0)
            ? AggregatorV3Interface(_chainlinkDivideAddress).decimals()
            : 0;

        CHAINLINK_NORMALIZATION =
            10 **
                (18 +
                    _multiplyDecimals -
                    _divideDecimals +
                    IERC20Metadata(_asset).decimals() -
                    IERC20Metadata(_underlyingFAsset).decimals());

        name = _name;
        MAX_ORACLE_DELAY = _maxOracleDelay;
        PRICE_MIN = _priceMin;
    }

    /// @notice The ```getPrices``` function is intended to return price of ERC4626 token based on the base asset
    /// @return _isBadData is always false, just sync to other oracle interfaces
    /// @return _priceLow is the lower of the prices
    /// @return _priceHigh is the higher of the prices
    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        uint256 price;
        (_isBadData, price) = _getChainlinkPrice();     // assetAmount * price = underlyingFAssetAmount
        if (_isBadData) revert CHAINLINK_BAD_PRICE();

        uint256 rate = IFAsset(FASSET).exchangeRateStored();    // underlyingFAssetAmount / rate = FAssetAmount, rate decimal is constant 18
        rate = price * 1e18 / rate;

        _priceHigh = rate > PRICE_MIN ? rate : PRICE_MIN;
        _priceLow = _priceHigh;
    }

    function _getChainlinkPrice() internal view returns (bool _isBadData, uint256 _price) {
        _price = uint256(1e36);

        if (CHAINLINK_MULTIPLY_ADDRESS != address(0)) {
            (, int256 _answer, , uint256 _updatedAt, ) = AggregatorV3Interface(CHAINLINK_MULTIPLY_ADDRESS)
                .latestRoundData();

            // If data is stale or negative, set bad data to true and return
            if (_answer <= 0 || (block.timestamp - _updatedAt > MAX_ORACLE_DELAY)) {
                _isBadData = true;
                return (_isBadData, _price);
            }
            _price = _price * uint256(_answer);
        }

        if (CHAINLINK_DIVIDE_ADDRESS != address(0)) {
            (, int256 _answer, , uint256 _updatedAt, ) = AggregatorV3Interface(CHAINLINK_DIVIDE_ADDRESS)
                .latestRoundData();

            // If data is stale or negative, set bad data to true and return
            if (_answer <= 0 || (block.timestamp - _updatedAt > MAX_ORACLE_DELAY)) {
                _isBadData = true;
                return (_isBadData, _price);
            }
            _price = _price / uint256(_answer);
        }

        // return price as ratio of underlyingFAsset/Asset including decimal differences
        // CHAINLINK_NORMALIZATION = 10**(18 + asset.decimals() - underlyingFAsset.decimals() + multiplyOracle.decimals() - divideOracle.decimals())
        _price = _price / CHAINLINK_NORMALIZATION;
    }
}
