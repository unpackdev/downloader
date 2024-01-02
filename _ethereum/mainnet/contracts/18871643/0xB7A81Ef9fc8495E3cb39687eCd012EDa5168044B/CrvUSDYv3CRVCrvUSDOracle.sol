// SPDX-License-Identifier: ISC
pragma solidity ^0.8.21;

import "./AggregatorV3Interface.sol";
import "./Math.sol";
import "./ICurvePool.sol";
import "./IYearnVault.sol";

/// @title CrvUSDYv3CRVCrvUSDOracle
/// @author Jason (Sturdy) https://github.com/iris112
/// @notice  An oracle for CrvUSD/Yv3CRVCrvUSD
interface ILLAMMA {
    function price_oracle() external view returns (uint256);
}

contract CrvUSDYv3CRVCrvUSDOracle {
    address private constant ETH_CRVUSD_AMM_CONTROLLER = 0x1681195C176239ac5E72d9aeBaCf5b2492E0C4ee;
    address private constant ETH_USD_CHAINLINK = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address private constant CRVUSD_USD_CHAINLINK = 0xEEf0C605546958c1f899b6fB336C20671f9cD49F;
    uint8 public constant DECIMALS = 18;

    address public immutable THREECRV_ETH_CHAINLINK;
    address public immutable CURVE_CRVUSD_3CRV_POOL;
    address public immutable YEARN_CRVUSD_3CRV_VAULT;
    uint256 public immutable MAX_ORACLE_DELAY;
    uint256 public immutable PRICE_MIN;

    string public name;

    error CHAINLINK_BAD_PRICE();

    constructor(
        uint256 _maxOracleDelay,
        uint256 _priceMin,
        address _ethUnitchainlinkAddress,
        address _curvePoolAddress,
        address _yearnVaultAddress,
        string memory _name
    ) {
        THREECRV_ETH_CHAINLINK = _ethUnitchainlinkAddress;
        CURVE_CRVUSD_3CRV_POOL = _curvePoolAddress;
        YEARN_CRVUSD_3CRV_VAULT = _yearnVaultAddress;
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
        uint256 yvLPTokenPriceInETH = _getYv3CRVCrvUSDPrice(crvUSDPriceInETH);

        uint256 rate = crvUSDPriceInETH * 1e18 / yvLPTokenPriceInETH;    // crvUSD/yv3CRVCrvUSD

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
     * @dev Get price for yearn Curve-(USDT/USDC/DAI/FRAX)-CrvUSD LP Token
     */
    function _getYv3CRVCrvUSDPrice(uint256 _crvUSDPrice) internal view returns (uint256) {
        // Get (USDT/USDC/DAI/FRAX) price from chainlink
        (, int256 _answer, , uint256 _updatedAt, ) = AggregatorV3Interface(THREECRV_ETH_CHAINLINK)
            .latestRoundData();     // 3CRV/ETH
        // If data is stale or negative, set bad data to true and return
        if (_answer <= 0 || (block.timestamp - _updatedAt > MAX_ORACLE_DELAY)) {
            revert CHAINLINK_BAD_PRICE();
        }

        uint256 minStable = Math.min(uint256(_answer), _crvUSDPrice);
        uint256 curveLPTokenPrice = (ICurvePool(CURVE_CRVUSD_3CRV_POOL).get_virtual_price() * minStable) / 1e18;

        return curveLPTokenPrice * IYearnVault(YEARN_CRVUSD_3CRV_VAULT).pricePerShare() / 1e18;
    }
}
