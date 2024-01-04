// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "./AggregatorV3Interface.sol";
import "./SafeCast.sol";
import "./SafeMath.sol";
import "./IEPriceOracle.sol";
import "./Library.sol";

/**
 * @title Elysia's price feed
 * @notice implements chainlink price aggregator
 * @author Elysia
 */
contract EPriceOracleEth is IEPriceOracle {
    using SafeCast for int256;
    using SafeMath for uint256;

    address public admin;

/// @notice Emitted when admin is changed
    event NewAdmin(address newAdmin);

    AggregatorV3Interface internal _priceFeed;

    constructor(address priceFeed_) {
        _priceFeed = AggregatorV3Interface(priceFeed_);
        admin = msg.sender;
    }

    function getPrice() external view override returns (uint256) {
        return _getEthPrice();
    }

    function _getEthPrice() internal view returns (uint256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = _priceFeed.latestRoundData();

        return price.toUint256().mul(1e10);
    }

    function setAdmin(address account) external {
        require(msg.sender == admin, "Restricted to admin.");

        admin = account;

        emit NewAdmin(account);
    }
}
