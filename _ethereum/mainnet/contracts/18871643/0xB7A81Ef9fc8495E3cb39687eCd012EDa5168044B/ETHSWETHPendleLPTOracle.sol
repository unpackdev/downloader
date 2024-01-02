// SPDX-License-Identifier: ISC
pragma solidity ^0.8.21;

import "./PendleLpOracleLib.sol";
import "./IPMarket.sol";
import "./AggregatorV3Interface.sol";
import "./Math.sol";

/// @title ETHSWETHPendleLPTOracle
/// @author Jason (Sturdy) https://github.com/iris112
/// @notice  An oracle for ETH/swETH Pendle LPT
interface IswETH {
    function swETHToETHRate() external view returns (uint256);
}

contract ETHSWETHPendleLPTOracle {
    using PendleLpOracleLib for IPMarket;

    address private constant SWETH = 0xf951E335afb289353dc249e82926178EaC7DEd78;
    address private constant REDSTONE_SWETH_ETH_PRICE = 0x061bB36F8b67bB922937C102092498dcF4619F86;
    uint8 public constant DECIMALS = 18;
    
    address public immutable PENDLE_LPT;
    uint32 public immutable TWAP_DURATION;
    uint256 public immutable MAX_ORACLE_DELAY;
    uint256 public immutable PRICE_MIN;

    string public name;

    error REDSTONE_BAD_PRICE();

    constructor(
        address _pendleLPT, 
        uint32 _twapDuration, 
        uint256 _maxOracleDelay,
        uint256 _priceMin,
        string memory _name
    ) {
        PENDLE_LPT = _pendleLPT;
        TWAP_DURATION = _twapDuration;
        name = _name;
        MAX_ORACLE_DELAY = _maxOracleDelay;
        PRICE_MIN = _priceMin;
    }

    /// @notice The ```getPrices``` function is intended to return price of ERC4626 token based on the base asset
    /// @return _isBadData is always false, just sync to other oracle interfaces
    /// @return _priceLow is the lower of the prices
    /// @return _priceHigh is the higher of the prices
    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        uint256 swETHRate = IswETH(SWETH).swETHToETHRate();
        (, int256 _answer, , uint256 _updatedAt, ) = AggregatorV3Interface(REDSTONE_SWETH_ETH_PRICE).latestRoundData();
        // If data is stale or negative, set bad data to true and return
        if (_answer <= 0 || (block.timestamp - _updatedAt > MAX_ORACLE_DELAY)) {
            revert REDSTONE_BAD_PRICE();
        }
        swETHRate = Math.min(uint256(_answer) * 1e10, swETHRate);       // redstone price decimal is 8
        
        uint256 lpRate = IPMarket(PENDLE_LPT).getLpToAssetRate(TWAP_DURATION);
        uint256 rate = (swETHRate * lpRate) / 1e18;       //  LPT/ETH
        rate = 1e36 / rate;     // ETH/LPT

        _priceHigh = rate > PRICE_MIN ? rate : PRICE_MIN;
        _priceLow = _priceHigh;
    }
}
