// SPDX-License-Identifier: ISC
pragma solidity ^0.8.21;

import "./AggregatorV3Interface.sol";
import "./Math.sol";
import "./ICurvePool.sol";

/// @title PxETHBalPxETHOracle
/// @author Jason (Sturdy) https://github.com/iris112
/// @notice  An oracle for PxETH/BalPxETH

contract PxETHBalPxETHOracle {
    uint8 public constant DECIMALS = 18;

    address public immutable BAL_PXETH_POOL;
    uint256 public immutable MAX_ORACLE_DELAY;
    uint256 public immutable PRICE_MIN;

    string public name;

    error CHAINLINK_BAD_PRICE();

    constructor(
        uint256 _maxOracleDelay,
        uint256 _priceMin,
        address _balPoolAddress,
        string memory _name
    ) {
        BAL_PXETH_POOL = _balPoolAddress;
        name = _name;
        MAX_ORACLE_DELAY = _maxOracleDelay;
        PRICE_MIN = _priceMin;
    }

    /// @notice The ```getPrices``` function is intended to return price of ERC4626 token based on the base asset
    /// @return _isBadData is always false, just sync to other oracle interfaces
    /// @return _priceLow is the lower of the prices
    /// @return _priceHigh is the higher of the prices
    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        // uint256 yvLPTokenPriceInETH = _getYv3CRVCrvUSDPrice(crvUSDPriceInETH);

        // uint256 rate = crvUSDPriceInETH * 1e18 / yvLPTokenPriceInETH;    // crvUSD/yv3CRVCrvUSD
        uint256 rate = 1e18;

        _priceHigh = rate > PRICE_MIN ? rate : PRICE_MIN;
        _priceLow = _priceHigh;
    }

    // /**
    //  * @dev Get price for yearn Curve-(USDT/USDC/DAI/FRAX)-CrvUSD LP Token
    //  */
    // function _getYv3CRVCrvUSDPrice(uint256 _crvUSDPrice) internal view returns (uint256) {
    //     // Get (USDT/USDC/DAI/FRAX) price from chainlink
    //     (, int256 _answer, , uint256 _updatedAt, ) = AggregatorV3Interface(THREECRV_ETH_CHAINLINK)
    //         .latestRoundData();     // 3CRV/ETH
    //     // If data is stale or negative, set bad data to true and return
    //     if (_answer <= 0 || (block.timestamp - _updatedAt > MAX_ORACLE_DELAY)) {
    //         revert CHAINLINK_BAD_PRICE();
    //     }

    //     uint256 minStable = Math.min(uint256(_answer), _crvUSDPrice);
    //     uint256 curveLPTokenPrice = (ICurvePool(BAL_PXETH_POOL).get_virtual_price() * minStable) / 1e18;

    //     return curveLPTokenPrice * IYearnVault(YEARN_CRVUSD_3CRV_VAULT).pricePerShare() / 1e18;
    // }
}
