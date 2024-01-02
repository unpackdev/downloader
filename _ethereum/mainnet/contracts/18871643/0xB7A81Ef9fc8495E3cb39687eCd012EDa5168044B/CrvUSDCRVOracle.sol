// SPDX-License-Identifier: ISC
pragma solidity ^0.8.21;

import "./AggregatorV3Interface.sol";
import "./Math.sol";

/// @title CrvUSDCRVOracle
/// @author Jason (Sturdy) https://github.com/iris112
/// @notice  An oracle for CrvUSD/CRV
interface ILLAMMA {
    function price_oracle() external view returns (uint256);
}

contract CrvUSDCRVOracle {
    address private constant ETH_CRVUSD_AMM_CONTROLLER = 0x1681195C176239ac5E72d9aeBaCf5b2492E0C4ee;
    address private constant ETH_USD_CHAINLINK = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address private constant CRV_USD_CHAINLINK = 0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f;
    address private constant CRVUSD_USD_CHAINLINK = 0xEEf0C605546958c1f899b6fB336C20671f9cD49F;
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
        uint256 rate = ILLAMMA(ETH_CRVUSD_AMM_CONTROLLER).price_oracle();  // ETH/crvUSD
        (, int256 _answer, , uint256 _updatedAt, ) = AggregatorV3Interface(ETH_USD_CHAINLINK)
            .latestRoundData();     // ETH/USD
        // If data is stale or negative, set bad data to true and return
        if (_answer <= 0 || (block.timestamp - _updatedAt > MAX_ORACLE_DELAY)) {
            revert CHAINLINK_BAD_PRICE();
        }
        rate = uint256(_answer) * 1e18 / rate;    // crvUSD/USD

        (, _answer, , _updatedAt, ) = AggregatorV3Interface(CRVUSD_USD_CHAINLINK)
            .latestRoundData();     // crvUSD/USD
        // If data is stale or negative, set bad data to true and return
        if (_answer <= 0 || (block.timestamp - _updatedAt > MAX_ORACLE_DELAY)) {
            revert CHAINLINK_BAD_PRICE();
        }
        rate = Math.min(rate, uint256(_answer));

        (, _answer, , _updatedAt, ) = AggregatorV3Interface(CRV_USD_CHAINLINK)
            .latestRoundData();     // CRV/USD
        // If data is stale or negative, set bad data to true and return
        if (_answer <= 0 || (block.timestamp - _updatedAt > MAX_ORACLE_DELAY)) {
            revert CHAINLINK_BAD_PRICE();
        }
        rate = rate * 1e18 / uint256(_answer);    // crvUSD/CRV

        _priceHigh = rate > PRICE_MIN ? rate : PRICE_MIN;
        _priceLow = _priceHigh;
    }
}
