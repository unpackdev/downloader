// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IUniswapV3Pool.sol";

import "./Equations.sol";
import "./FullMath.sol";
import "./TickMath.sol";
import "./UINT512.sol";

import "./IAloePredictions.sol";

import "./AloePredictionsState.sol";

/*
                                                                                                                        
                                                   #                                                                    
                                                  ###                                                                   
                                                  #####                                                                 
                               #                 #######                                *###*                           
                                ###             #########                         ########                              
                                #####         ###########                   ###########                                 
                                ########    ############               ############                                     
                                 ########    ###########         *##############                                        
                                ###########   ########      #################                                           
                                ############   ###      #################                                               
                                ############       ##################                                                   
                               #############    #################*         *#############*                              
                              ##############    #############      #####################################                
                             ###############   ####******      #######################*                                 
                           ################                                                                             
                         #################   *############################*                                             
                           ##############    ######################################                                     
                               ########    ################*                     **######*                              
                                   ###    ###                                                                           
                                                                                                                        
         ___       ___       ___       ___            ___       ___       ___       ___       ___       ___       ___   
        /\  \     /\__\     /\  \     /\  \          /\  \     /\  \     /\  \     /\  \     /\  \     /\  \     /\__\  
       /::\  \   /:/  /    /::\  \   /::\  \        /::\  \   /::\  \   /::\  \   _\:\  \    \:\  \   /::\  \   /:/  /  
      /::\:\__\ /:/__/    /:/\:\__\ /::\:\__\      /:/\:\__\ /::\:\__\ /::\:\__\ /\/::\__\   /::\__\ /::\:\__\ /:/__/   
      \/\::/  / \:\  \    \:\/:/  / \:\:\/  /      \:\ \/__/ \/\::/  / \/\::/  / \::/\/__/  /:/\/__/ \/\::/  / \:\  \   
        /:/  /   \:\__\    \::/  /   \:\/  /        \:\__\     /:/  /     \/__/   \:\__\    \/__/      /:/  /   \:\__\  
        \/__/     \/__/     \/__/     \/__/          \/__/     \/__/               \/__/               \/__/     \/__/  
*/

uint256 constant TWO_144 = 2**144;
uint256 constant TWO_80 = 2**80;

/// @title Aloe predictions market
/// @author Aloe Capital LLC
contract AloePredictions is AloePredictionsState, IAloePredictions {
    using SafeERC20 for IERC20;
    using UINT512Math for UINT512;

    /// @dev The number of standard deviations to +/- from the mean when computing ground truth bounds
    uint256 public constant GROUND_TRUTH_STDDEV_SCALE = 2;

    /// @dev The minimum length of an epoch, in seconds. Epochs may be longer if no one calls `advance`
    uint32 public constant EPOCH_LENGTH_SECONDS = 3600;

    /// @dev The ALOE token used for staking
    IERC20 public immutable ALOE;

    /// @dev The Uniswap pair for which predictions should be made
    IUniswapV3Pool public immutable UNI_POOL;

    /// @dev For reentrancy check
    bool private locked;

    modifier lock() {
        require(!locked, "Aloe: Locked");
        locked = true;
        _;
        locked = false;
    }

    constructor(IERC20 _ALOE, IUniswapV3Pool _UNI_POOL) AloePredictionsState() {
        ALOE = _ALOE;
        UNI_POOL = _UNI_POOL;

        // Ensure we have an hour of data, assuming Uniswap interaction every 10 seconds
        _UNI_POOL.increaseObservationCardinalityNext(360);
    }

    /// @inheritdoc IAloePredictionsDerivedState
    function current() external view override returns (Bounds memory, bool) {
        require(epoch != 0, "Aloe: No data yet");
        return (summaries[epoch - 1].aggregate, didInvertPrices);
    }

    /// @inheritdoc IAloePredictionsDerivedState
    function epochExpectedEndTime() public view override returns (uint32) {
        unchecked {return epochStartTime + EPOCH_LENGTH_SECONDS;}
    }

    /// @inheritdoc IAloePredictionsActions
    function advance() external virtual override lock {
        require(uint32(block.timestamp) > epochExpectedEndTime(), "Aloe: Too early");
        epochStartTime = uint32(block.timestamp);

        summaries[epoch].aggregate = aggregate();

        if (epoch != 0) {
            (Bounds memory groundTruth, bool shouldInvertPricesNext) = fetchGroundTruth();
            emit FetchedGroundTruth(groundTruth.lower, groundTruth.upper, didInvertPrices);

            summaries[epoch - 1].groundTruth = groundTruth;
            didInvertPrices = shouldInvertPrices;
            shouldInvertPrices = shouldInvertPricesNext;
        }

        epoch++;
        emit Advanced(epoch, uint32(block.timestamp));
    }

    /// @inheritdoc IAloePredictionsActions
    function submitProposal(
        uint176 lower,
        uint176 upper,
        uint80 stake
    ) external override lock returns (uint40 key) {
        require(ALOE.transferFrom(msg.sender, address(this), stake), "Aloe: Provide ALOE");

        key = _submitProposal(stake, lower, upper);
        _organizeProposals(key, stake);

        emit ProposalSubmitted(msg.sender, epoch, key, lower, upper, stake);
    }

    /// @inheritdoc IAloePredictionsActions
    function updateProposal(
        uint40 key,
        uint176 lower,
        uint176 upper
    ) external override {
        _updateProposal(key, lower, upper);
        emit ProposalUpdated(msg.sender, epoch, key, lower, upper);
    }

    /// @inheritdoc IAloePredictionsActions
    function claimReward(uint40 key) external override lock {
        Proposal storage proposal = proposals[key];
        require(proposal.stake != 0, "Aloe: Nothing to claim");

        EpochSummary storage summary = summaries[proposal.epoch];
        require(summary.groundTruth.lower != 0, "Aloe: Need ground truth");
        require(summary.groundTruth.upper != 0, "Aloe: Need ground truth");

        if (summary.accumulators.proposalCount == 1) {
            require(ALOE.transfer(proposal.source, proposal.stake), "Aloe: failed to reward");
            emit ClaimedReward(proposal.source, proposal.epoch, key, proposal.stake);
            delete proposals[key];
        }

        uint256 lowerError =
            proposal.lower > summary.groundTruth.lower
                ? proposal.lower - summary.groundTruth.lower
                : summary.groundTruth.lower - proposal.lower;
        uint256 upperError =
            proposal.upper > summary.groundTruth.upper
                ? proposal.upper - summary.groundTruth.upper
                : summary.groundTruth.upper - proposal.upper;

        UINT512 memory sumOfSquaredErrors =
            Equations.eqn1(
                summary.accumulators.sumOfSquaredBounds,
                summary.accumulators.sumOfLowerBounds,
                summary.accumulators.sumOfUpperBounds,
                summary.accumulators.proposalCount,
                summary.groundTruth.lower,
                summary.groundTruth.upper
            );
        UINT512 memory sumOfSquaredErrorsWeighted =
            Equations.eqn1(
                summary.accumulators.sumOfSquaredBoundsWeighted,
                summary.accumulators.sumOfLowerBoundsWeighted,
                summary.accumulators.sumOfUpperBoundsWeighted,
                summary.accumulators.stakeTotal,
                summary.groundTruth.lower,
                summary.groundTruth.upper
            );

        UINT512 memory temp;

        // Compute reward numerator
        UINT512 memory numer = UINT512(sumOfSquaredErrors.LS, sumOfSquaredErrors.MS);
        // --> Subtract current proposal's squared error
        (temp.LS, temp.MS) = FullMath.square512(lowerError);
        (numer.LS, numer.MS) = numer.sub(temp.LS, temp.MS);
        (temp.LS, temp.MS) = FullMath.square512(upperError);
        (numer.LS, numer.MS) = numer.sub(temp.LS, temp.MS);
        // --> Weight entire numerator by proposal's stake
        (numer.LS, numer.MS) = numer.muls(proposal.stake);

        // Compute reward denominator
        UINT512 memory denom = UINT512(sumOfSquaredErrors.LS, sumOfSquaredErrors.MS);
        // --> Scale this initial term by total stake
        (denom.LS, denom.MS) = denom.muls(summary.accumulators.stakeTotal);
        // --> Subtract sum of all weighted squared errors
        (denom.LS, denom.MS) = denom.sub(sumOfSquaredErrorsWeighted.LS, sumOfSquaredErrorsWeighted.MS);

        // Now our 4 key numbers are available: numerLS, numerMS, denomLS, denomMS
        uint256 reward;
        if (denom.MS == 0) {
            // If denominator MS is 0, then numerator MS is 0 as well.
            // This simplifies things substantially:
            reward = FullMath.mulDiv(summary.accumulators.stakeTotal, numer.LS, denom.LS);
        } else {
            if (numer.LS != 0) {
                reward = 257 + FullMath.log2floor(denom.MS) - FullMath.log2floor(numer.LS);
                reward = reward < 80 ? summary.accumulators.stakeTotal / (2**reward) : 0;
            }
            if (numer.MS != 0) {
                reward += FullMath.mulDiv(
                    summary.accumulators.stakeTotal,
                    TWO_80 * numer.MS,
                    TWO_80 * denom.MS + FullMath.mulDiv(TWO_80, denom.LS, type(uint256).max)
                );
            }
        }

        require(ALOE.transfer(proposal.source, reward), "Aloe: failed to reward");
        emit ClaimedReward(proposal.source, proposal.epoch, key, uint80(reward));
        delete proposals[key];
    }

    /// @inheritdoc IAloePredictionsDerivedState
    function aggregate() public view override returns (Bounds memory bounds) {
        Accumulators memory accumulators = summaries[epoch].accumulators;

        require(accumulators.stakeTotal != 0, "Aloe: No proposals with stake");

        uint176 mean = uint176(accumulators.stake1stMomentRaw / accumulators.stakeTotal);
        uint256 stake1stMomentRawLower;
        uint256 stake1stMomentRawUpper;
        uint176 stake2ndMomentNormLower;
        uint176 stake2ndMomentNormUpper;
        uint40 i;

        // It's more gas efficient to read from memory copy
        uint40[NUM_PROPOSALS_TO_AGGREGATE] memory keysToAggregate = highestStakeKeys;

        unchecked {
            for (i = 0; i < NUM_PROPOSALS_TO_AGGREGATE && i < accumulators.proposalCount; i++) {
                Proposal storage proposal = proposals[keysToAggregate[i]];

                if ((proposal.lower < mean) && (proposal.upper < mean)) {
                    // Proposal is entirely below the mean
                    stake1stMomentRawLower += uint256(proposal.stake) * uint256(proposal.upper - proposal.lower);
                } else if (proposal.lower < mean) {
                    // Proposal includes the mean
                    stake1stMomentRawLower += uint256(proposal.stake) * uint256(mean - proposal.lower);
                    stake1stMomentRawUpper += uint256(proposal.stake) * uint256(proposal.upper - mean);
                } else {
                    // Proposal is entirely above the mean
                    stake1stMomentRawUpper += uint256(proposal.stake) * uint256(proposal.upper - proposal.lower);
                }
            }

            for (i = 0; i < NUM_PROPOSALS_TO_AGGREGATE && i < accumulators.proposalCount; i++) {
                Proposal storage proposal = proposals[keysToAggregate[i]];

                if ((proposal.lower < mean) && (proposal.upper < mean)) {
                    // Proposal is entirely below the mean
                    // b = mean - proposal.lower
                    // a = mean - proposal.upper
                    // b**2 - a**2 = (b-a)(b+a) = (proposal.upper - proposal.lower)(2*mean - proposal.upper - proposal.lower)
                    //      = 2 * (proposalSpread)(mean - proposalCenter)

                    // These fit in uint176, using uint256 to avoid phantom overflow later on
                    uint256 proposalCenter = (uint256(proposal.lower) + uint256(proposal.upper)) >> 1;
                    uint256 proposalSpread = proposal.upper - proposal.lower;

                    stake2ndMomentNormLower += uint176(
                        FullMath.mulDiv(
                            uint256(proposal.stake) * proposalSpread,
                            mean - proposalCenter,
                            stake1stMomentRawLower
                        )
                    );
                } else if (proposal.lower < mean) {
                    // Proposal includes the mean

                    // These fit in uint176, using uint256 to avoid phantom overflow later on
                    uint256 diffLower = mean - proposal.lower;
                    uint256 diffUpper = proposal.upper - mean;

                    stake2ndMomentNormLower += uint176(
                        FullMath.mulDiv(uint256(proposal.stake) * diffLower, diffLower, stake1stMomentRawLower << 1)
                    );
                    stake2ndMomentNormUpper += uint176(
                        FullMath.mulDiv(uint256(proposal.stake) * diffUpper, diffUpper, stake1stMomentRawUpper << 1)
                    );
                } else {
                    // Proposal is entirely above the mean
                    // b = proposal.upper - mean
                    // a = proposal.lower - mean
                    // b**2 - a**2 = (b-a)(b+a) = (proposal.upper - proposal.lower)(proposal.upper + proposal.lower - 2*mean)
                    //      = 2 * (proposalSpread)(proposalCenter - mean)

                    // These fit in uint176, using uint256 to avoid phantom overflow later on
                    uint256 proposalCenter = (uint256(proposal.lower) + uint256(proposal.upper)) >> 1;
                    uint256 proposalSpread = proposal.upper - proposal.lower;

                    stake2ndMomentNormUpper += uint176(
                        FullMath.mulDiv(
                            uint256(proposal.stake) * proposalSpread,
                            proposalCenter - mean,
                            stake1stMomentRawUpper
                        )
                    );
                }
            }
        }

        bounds.lower = mean - stake2ndMomentNormLower;
        bounds.upper = mean + stake2ndMomentNormUpper;
    }

    /// @inheritdoc IAloePredictionsDerivedState
    function fetchGroundTruth() public view override returns (Bounds memory bounds, bool shouldInvertPricesNext) {
        (int56[] memory tickCumulatives, ) = UNI_POOL.observe(selectedOracleTimetable());
        uint176 mean = TickMath.getSqrtRatioAtTick(int24((tickCumulatives[9] - tickCumulatives[0]) / 3240));
        shouldInvertPricesNext = mean < TWO_80;

        // After accounting for possible inversion, compute mean price over the entire 54 minute period
        if (didInvertPrices) mean = type(uint160).max / mean;
        mean = uint176(FullMath.mulDiv(mean, mean, TWO_144));

        // stat will take on a few different statistical values
        // Here it's MAD (Mean Absolute Deviation), except not yet divided by number of samples
        uint184 stat;
        uint176 sample;

        for (uint8 i = 0; i < 9; i++) {
            sample = TickMath.getSqrtRatioAtTick(int24((tickCumulatives[i + 1] - tickCumulatives[i]) / 360));

            // After accounting for possible inversion, compute mean price over a 6 minute period
            if (didInvertPrices) sample = type(uint160).max / sample;
            sample = uint176(FullMath.mulDiv(sample, sample, TWO_144));

            // Accumulate
            stat += sample > mean ? sample - mean : mean - sample;
        }

        // MAD = stat / n, here n = 10
        // STDDEV = MAD * sqrt(2/pi) for a normal distribution
        // We want bounds to be +/- G*stddev, so we have an additional factor of G here
        stat = uint176((uint256(stat) * GROUND_TRUTH_STDDEV_SCALE * 79788) / 1000000);
        // Compute mean +/- stat, but be careful not to overflow
        bounds.lower = mean > stat ? uint176(mean - stat) : 0;
        bounds.upper = uint184(mean) + stat > type(uint176).max ? type(uint176).max : uint176(mean + stat);
    }

    /// @inheritdoc IAloePredictionsDerivedState
    function selectedOracleTimetable() public pure override returns (uint32[] memory secondsAgos) {
        secondsAgos = new uint32[](10);
        secondsAgos[0] = 3420;
        secondsAgos[1] = 3060;
        secondsAgos[2] = 2700;
        secondsAgos[3] = 2340;
        secondsAgos[4] = 1980;
        secondsAgos[5] = 1620;
        secondsAgos[6] = 1260;
        secondsAgos[7] = 900;
        secondsAgos[8] = 540;
        secondsAgos[9] = 180;
    }
}
