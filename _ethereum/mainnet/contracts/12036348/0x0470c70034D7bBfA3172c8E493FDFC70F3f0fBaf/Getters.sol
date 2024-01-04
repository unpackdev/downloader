// SPDX-License-Identifier: MIT

pragma solidity =0.5.16;

import "./State.sol";

/**
 * NOTE: Contract MahaswapV1Pair should be the owner of this controller.
 */
contract Getters is State {
    function getLatestQuoteInUSD() public view returns (uint256) {
        if (address(quotePriceFeed) == address(0)) return 1e18;

        uint256 decimalUsed = quotePriceFeed.decimals();
        uint256 decimalDiff = uint256(18).sub(decimalUsed);

        (uint80 roundID, int256 price, uint256 startedAt, uint256 timeStamp, uint80 answeredInRound) =
            quotePriceFeed.latestRoundData();

        if (decimalDiff > 0) return uint256(price).mul(uint256(10**decimalDiff));
        return uint256(price);
    }

    function getPenaltyPrice() public view returns (uint256) {
        // If (useOracle) then get penalty price from an oracle
        // else get from a variable.
        // This variable is settable from the factory.
        return penaltyPrice;
    }

    function getRewardIncentivePrice() public view returns (uint256) {
        // If (useOracle) then get reward price from an oracle
        // else get from a variable.
        // This variable is settable from the factory.
        return rewardPrice;
    }
}
