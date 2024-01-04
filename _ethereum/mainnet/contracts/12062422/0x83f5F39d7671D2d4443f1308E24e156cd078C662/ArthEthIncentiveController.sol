// SPDX-License-Identifier: MIT

pragma solidity =0.5.16;

import "./Epoch.sol";
import "./Setters.sol";
import "./Math.sol";
import "./IBurnableERC20.sol";
import "./IMahaswapV1Pair.sol";
import "./IIncentiveController.sol";
import "./IChainlinkAggregatorV3.sol";

/**
 * NOTE: Contract MahaswapV1Pair should be the owner of this controller.
 */
contract ArthEthIncentiveController is IIncentiveController, Setters, Epoch {
    /**
     * Constructor.
     */
    constructor(
        address _pairAddress,
        address _protocolTokenAddress,
        address _ecosystemFund,
        address _incentiveToken,
        uint256 _rewardPerEpoch,
        uint256 _arthToMahaRate,
        uint256 _period,
        address _quotePriceFeed
    )
        public
        Epoch(
            _period, /* 12 hour epochs */
            block.timestamp,
            0
        )
    {
        pairAddress = _pairAddress;
        ecosystemFund = _ecosystemFund;
        protocolTokenAddress = _protocolTokenAddress;
        incentiveToken = IBurnableERC20(_incentiveToken);
        isTokenAProtocolToken = IMahaswapV1Pair(_pairAddress).token0() == _protocolTokenAddress;
        rewardPerEpoch = _rewardPerEpoch;
        arthToMahaRate = _arthToMahaRate;
        availableRewardThisEpoch = rewardPerEpoch;
        quotePriceFeed = IChainlinkAggregatorV3(_quotePriceFeed);
    }

    function estimatePenaltyToCharge(
        uint256 price,
        uint256 liquidity,
        uint256 sellVolume
    ) public view returns (uint256) {
        uint256 targetPrice = getPenaltyPrice();

        // % of pool = sellVolume / liquidity
        // % of deviation from target price = (tgt_price - price) / price
        // amountToburn = sellVolume * % of deviation from target price * % of pool * 100
        if (price >= targetPrice) return 0;

        uint256 percentOfPool = sellVolume.mul(10000).div(liquidity);
        uint256 deviationFromTarget = targetPrice.sub(price).mul(10000).div(targetPrice);

        // A number from 0-100%.
        uint256 feeToCharge = Math.max(percentOfPool, deviationFromTarget);

        // NOTE: Shouldn't this be multiplied by 10000 instead of 100
        // NOTE: multiplication by 100, is removed in the mock controller
        // Can 2x, 3x, ... the penalty.
        return sellVolume.mul(feeToCharge).mul(arthToMahaRate).mul(penaltyMultiplier).div(10000 * 100000 * 1e18);
    }

    function estimateRewardToGive(
        uint256 price,
        uint256 liquidity,
        uint256 buyVolume
    ) public view returns (uint256) {
        uint256 targetPrice = getRewardIncentivePrice();

        // % of pool = buyVolume / liquidity
        // % of deviation from target price = (tgt_price - price) / price
        // rewardToGive = buyVolume * % of deviation from target price * % of pool * 100
        if (price >= targetPrice) return 0;

        uint256 percentOfPool = buyVolume.mul(10000).div(liquidity);
        uint256 deviationFromTarget = targetPrice.sub(price).mul(10000).div(targetPrice);

        // A number from 0-100%.
        uint256 rewardToGive = Math.min(percentOfPool, deviationFromTarget);

        uint256 calculatedRewards =
            rewardPerEpoch.mul(rewardToGive).mul(arthToMahaRate).mul(rewardMultiplier).div(10000 * 100000 * 1e18);

        return Math.min(availableRewardThisEpoch, calculatedRewards);
    }

    function _penalizeTrade(
        uint256 price,
        uint256 sellVolume,
        uint256 liquidity,
        address to
    ) private {
        uint256 amountToPenalize = estimatePenaltyToCharge(price, liquidity, sellVolume);

        if (amountToPenalize > 0) {
            // NOTE: amount has to be approved from frontend.

            // Burn and charge a fraction of the penalty.
            incentiveToken.burnFrom(to, amountToPenalize.mul(penaltyToBurn).div(100));

            // Keep a fraction of the penalty as funds for paying out rewards.
            uint256 amountToKeep = amountToPenalize.mul(penaltyToKeep).div(100);
            // Get the amount to keep in the contract.
            incentiveToken.transferFrom(to, address(this), amountToKeep);
            // Increase the variable to reflect this transfer.
            rewardCollectedFromPenalties = rewardCollectedFromPenalties.add(amountToKeep);

            // Send a fraction of the penalty to fund the ecosystem.
            incentiveToken.transferFrom(to, ecosystemFund, amountToPenalize.mul(penaltyToRedirect).div(100));
        }
    }

    function _incentiviseTrade(
        uint256 price,
        uint256 buyVolume,
        uint256 liquidity,
        address to
    ) private {
        // Calculate the amount as per volumne and rate.
        uint256 amountToReward = estimateRewardToGive(price, liquidity, buyVolume);

        if (amountToReward > 0) {
            availableRewardThisEpoch = availableRewardThisEpoch.sub(amountToReward);

            // Send reward to the appropriate address.
            incentiveToken.transfer(to, amountToReward);
        }
    }

    /**
     * This is the function that burns the MAHA and returns how much ARTH should
     * actually be spent.
     *
     * Note we are always selling tokenA.
     */
    function conductChecks(
        uint112 reserveA,
        uint112 reserveB,
        uint256 priceALast,
        uint256 priceBLast,
        uint256 amountOutA,
        uint256 amountOutB,
        uint256 amountInA,
        uint256 amountInB,
        address from,
        address to
    ) external onlyPair {
        // calculate price after the trade has been made
        uint256 reserveAFinal = reserveA + amountInA - amountOutA;
        uint256 reserveBFinal = reserveB + amountInB - amountOutB;
        // Get the price of quote in USD.
        uint256 quotePriceInUSD = getLatestQuoteInUSD();

        if (isTokenAProtocolToken) {
            // then A is ARTH
            uint256 price = uint256(reserveBFinal).mul(quotePriceInUSD).div(uint256(reserveAFinal));
            _conductChecks(reserveA, price, amountOutA, amountInA, to);
        } else {
            // then B is ARTH
            uint256 price = uint256(reserveAFinal).mul(quotePriceInUSD).div(uint256(reserveBFinal));
            _conductChecks(reserveB, price, amountOutB, amountInB, to);
        }
    }

    function _conductChecks(
        uint112 reserveA, // ARTH liquidity
        uint256 priceA, // ARTH price
        uint256 amountOutA, // ARTH being bought
        uint256 amountInA, // ARTH being sold
        address to
    ) private {
        // capture volume and snapshot it every epoch.
        if (getCurrentEpoch() >= getNextEpoch()) _updateForEpoch();

        // Check if we are selling and if we are blow the target price?
        if (amountInA > 0) {
            // Check if we are below the targetPrice.
            uint256 penaltyTargetPrice = getPenaltyPrice();

            if (priceA < penaltyTargetPrice) {
                // is the user expecting some DAI? if so then this is a sell order
                // Calculate the amount of tokens sent.
                _penalizeTrade(priceA, amountInA, reserveA, to);

                // stop here to save gas
                return;
            }
        }

        // Check if we are buying and below the target price
        if (amountOutA > 0 && priceA < getRewardIncentivePrice() && availableRewardThisEpoch > 0) {
            // is the user expecting some ARTH? if so then this is a sell order
            // If we are buying the main protocol token, then we incentivize the tx sender.
            _incentiviseTrade(priceA, amountOutA, reserveA, to);
        }
    }

    function _updateForEpoch() private {
        // Consider the reward pending from previous epoch and
        // rewards capacity that was increased from penalizing people (AIP9 2nd point).
        availableRewardThisEpoch = rewardPerEpoch.add(rewardCollectedFromPenalties);
        rewardCollectedFromPenalties = 0;

        lastExecutedAt = block.timestamp;
    }

    function refundIncentiveToken() external onlyOwner {
        incentiveToken.transfer(msg.sender, incentiveToken.balanceOf(address(this)));
    }
}
