// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Math.sol";

interface IChainlinkOracle {
    function latestAnswer() external view returns (uint256);
}

abstract contract PriceGuard {
    event PausePriceGuard(address indexed sender, bool paused);

    uint256 public constant SPREAD_TOLERANCE = 10; // max 10% spread
    address public constant CHAINLINK_ORACLE = address(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    bool public priceGuardPaused = false;

    modifier verifyPrice(uint256 priceETHUSD) {
        if (!priceGuardPaused) {
            uint256 oraclePrice = chainlinkPriceETHUSD();
            uint256 min = Math.min(priceETHUSD, oraclePrice);
            uint256 max = Math.max(priceETHUSD, oraclePrice);
            uint256 upperLimit = (min * (SPREAD_TOLERANCE + 100)) / 100;
            require(max <= upperLimit, "PriceOracle ETHUSD");
        }
        _;
    }

    /**
     * returns price of ETH in USD (6 decimals)
     */
    function chainlinkPriceETHUSD() public view returns (uint256) {
        return IChainlinkOracle(CHAINLINK_ORACLE).latestAnswer() / 100; // chainlink answer is 8 decimals
    }

    function _pausePriceGuard(bool _paused) internal {
        priceGuardPaused = _paused;
        emit PausePriceGuard(msg.sender, priceGuardPaused);
    }
}
