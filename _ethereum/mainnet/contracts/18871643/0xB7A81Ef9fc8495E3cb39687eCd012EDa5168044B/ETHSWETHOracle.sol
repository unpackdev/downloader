// SPDX-License-Identifier: ISC
pragma solidity ^0.8.21;

import "./Math.sol";
import "./AggregatorV3Interface.sol";

/// @title ETHSWETHOracle
/// @author Jason (Sturdy) https://github.com/iris112
/// @notice  An oracle for ETH/swETH
interface IswETH {
    function swETHToETHRate() external view returns (uint256);
}

contract ETHSWETHOracle {
    address private constant TOKEN = 0xf951E335afb289353dc249e82926178EaC7DEd78;
    address private constant REDSTONE_SWETH_ETH_PRICE = 0x061bB36F8b67bB922937C102092498dcF4619F86;
    uint8 public constant DECIMALS = 18;
    
    uint256 public immutable MAX_ORACLE_DELAY;
    uint256 public immutable PRICE_MIN;

    string public name;

    error REDSTONE_BAD_PRICE();

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
        uint256 rate = IswETH(TOKEN).swETHToETHRate();
        (, int256 _answer, , uint256 _updatedAt, ) = AggregatorV3Interface(REDSTONE_SWETH_ETH_PRICE).latestRoundData();
        // If data is stale or negative, set bad data to true and return
        if (_answer <= 0 || (block.timestamp - _updatedAt > MAX_ORACLE_DELAY)) {
            revert REDSTONE_BAD_PRICE();
        }
        rate = Math.min(uint256(_answer) * 1e10, rate);       // redstone price decimal is 8
        rate = 1e36 / rate;     //  ETH/SWETH

        _priceHigh = rate > PRICE_MIN ? rate : PRICE_MIN;
        _priceLow = _priceHigh;
    }
}
