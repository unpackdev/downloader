// SPDX-License-Identifier: MIT
pragma solidity ^0.6.11;

import "./SafeMath.sol";

contract OracleV2 {
    using SafeMath for uint;

    event ExchangeRatePosted(
        address operator,
        uint prevExchangeRate,
        uint newExchangeRate
    );

    address public admin;
    address public poster;
    uint public currentExchangeRate;
    uint public lastUpdated;

    /// @notice The change of exchange rate shouldn't exceed 1%.
    uint public constant MAX_SWING = 0.01e18;

    /// @notice Poster couldn't update the exchange rate within 12 hours.
    uint public constant UPDATE_PERIOD = 12 hours;

    constructor(address _poster) public {
        admin = msg.sender;
        poster = _poster;
    }

    function setAdmin(address _admin) external {
        require(msg.sender == admin, "!admin");
        admin = _admin;
    }

    function setPoster(address _poster) external {
        require(msg.sender == admin, "!admin");
        poster = _poster;
    }

    /// @notice Update the exchange rate by admin. It's for emergency.
    /// @param newExchangeRate The new exchange rate.
    function setExchangeRate(uint newExchangeRate) external {
        require(msg.sender == admin, "!admin");

        emit ExchangeRatePosted(msg.sender, currentExchangeRate, newExchangeRate);
        currentExchangeRate = newExchangeRate;
        lastUpdated = block.timestamp;
    }

    /// @notice Update the exchange rate by poster. It would have a cooldown period and a max swing limit.
    /// @param newExchangeRate The new exchange rate.
    function updateExchangeRate(uint newExchangeRate) external {
        require(msg.sender == poster, "!poster");
        require(block.timestamp > lastUpdated.add(UPDATE_PERIOD), "cooldown");

        if (currentExchangeRate > 0) {
            uint maxDiff = currentExchangeRate.mul(MAX_SWING).div(1e18);
            require(newExchangeRate < currentExchangeRate.add(maxDiff), "upper cap");
            require(newExchangeRate > currentExchangeRate.sub(maxDiff), "lower cap");
        }

        emit ExchangeRatePosted(msg.sender, currentExchangeRate, newExchangeRate);
        currentExchangeRate = newExchangeRate;
        lastUpdated = block.timestamp;
    }

    /// @notice Get the exchange rate between ETH and CETH2.
    /// @return The exchange rate.
    function exchangeRate() external view returns (uint) {
        return currentExchangeRate;
    }
}
