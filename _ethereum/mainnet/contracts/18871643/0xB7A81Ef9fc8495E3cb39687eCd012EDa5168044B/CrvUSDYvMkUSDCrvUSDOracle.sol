// SPDX-License-Identifier: ISC
pragma solidity ^0.8.21;

import "./AggregatorV3Interface.sol";
import "./Math.sol";
import "./ICurvePool.sol";
import "./IYearnVault.sol";

/// @title CrvUSDYvMkUSDCrvUSDOracle
/// @author Jason (Sturdy) https://github.com/iris112
/// @notice  An oracle for CrvUSD/YvMkUSDCrvUSD
interface ILLAMMA {
    function price_oracle() external view returns (uint256);
}

contract CrvUSDYvMkUSDCrvUSDOracle {
    address private constant ETH_CRVUSD_AMM_CONTROLLER = 0x1681195C176239ac5E72d9aeBaCf5b2492E0C4ee;
    address private constant ETH_USD_CHAINLINK = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address private constant CRVUSD_USD_CHAINLINK = 0xEEf0C605546958c1f899b6fB336C20671f9cD49F;
    address public constant CURVE_CRVUSD_MKUSD_POOL = 0x3de254A0f838a844F727fee81040e0FA7884B935;
    address public constant YEARN_CRVUSD_MKUSD_VAULT = 0xd901DCf4948a29d7D9D7E015AAF61591825AC267;
    uint8 public constant DECIMALS = 18;
    
    uint256 public immutable MAX_ORACLE_DELAY;
    uint256 public immutable PRICE_MIN;

    string public name;

    error CHAINLINK_BAD_PRICE();

    constructor(
        uint256 _maxOracleDelay,
        uint256 _priceMin,
        string memory _name
    ) {
        name = _name;
        MAX_ORACLE_DELAY = _maxOracleDelay;
        PRICE_MIN = _priceMin;
    }

    /// @notice The ```getPrices``` function is intended to return price of ERC4626 token based on the base asset
    /// @return _isBadData is always false, just sync to other oracle interfaces
    /// @return _priceLow is the lower of the prices
    /// @return _priceHigh is the higher of the prices
    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        uint256 crvUSDPriceInETH = _getCrvUSDPrice();
        uint256 yvLPTokenPriceInETH = _getYvMkUSDCrvUSDPrice(crvUSDPriceInETH);

        uint256 rate = crvUSDPriceInETH * 1e18 / yvLPTokenPriceInETH;    // crvUSD/yvMkUSDCrvUSD

        _priceHigh = rate > PRICE_MIN ? rate : PRICE_MIN;
        _priceLow = _priceHigh;
    }

    /**
     * @dev Get price for crvUSD
     */
    function _getCrvUSDPrice() internal view returns (uint256) {
        // Get crvUSD price from AMM controller
        uint256 crvUSDPrice;
        uint256 rate = ILLAMMA(ETH_CRVUSD_AMM_CONTROLLER).price_oracle();  // ETH/crvUSD
        rate = 1e36 / rate; // crvUSD/ETH

        // Get crvUSD price from chainlink
        (, int256 _answer, , uint256 _updatedAt, ) = AggregatorV3Interface(CRVUSD_USD_CHAINLINK)
            .latestRoundData();     // crvUSD/USD
        // If data is stale or negative, set bad data to true and return
        if (_answer <= 0 || (block.timestamp - _updatedAt > MAX_ORACLE_DELAY)) {
            revert CHAINLINK_BAD_PRICE();
        }
        crvUSDPrice = uint256(_answer);

        // Get ETH price from chainlink
        (, _answer, , _updatedAt, ) = AggregatorV3Interface(ETH_USD_CHAINLINK)
            .latestRoundData();     // ETH/USD
        // If data is stale or negative, set bad data to true and return
        if (_answer <= 0 || (block.timestamp - _updatedAt > MAX_ORACLE_DELAY)) {
            revert CHAINLINK_BAD_PRICE();
        }
        crvUSDPrice = crvUSDPrice * 1e26 / uint256(_answer);    // crvUSD/ETH

        return Math.min(rate, crvUSDPrice);
    }

    /**
     * @dev Get price for yearn Curve-MKUSD-CrvUSD LP Token
     */
    function _getYvMkUSDCrvUSDPrice(uint256 _crvUSDPrice) internal view returns (uint256) {
        // Get MKUSD price from curve pool
        uint256 mkUSDRatio = ICurvePool(CURVE_CRVUSD_MKUSD_POOL).price_oracle();
        uint256 minStable = Math.min(mkUSDRatio, 1e18) * _crvUSDPrice / 1e18;
        uint256 curveLPTokenPrice = (ICurvePool(CURVE_CRVUSD_MKUSD_POOL).get_virtual_price() * minStable) / 1e18;

        return curveLPTokenPrice * IYearnVault(YEARN_CRVUSD_MKUSD_VAULT).pricePerShare() / 1e18;
    }
}
