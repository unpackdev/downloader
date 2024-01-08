// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./SafeMath.sol";
import "./Math.sol";

import "./IPolicyBook.sol";
import "./IPolicyQuote.sol";

import "./Globals.sol";

contract PolicyQuote is IPolicyQuote {
    using Math for uint256;
    using SafeMath for uint256;

    uint256 public constant RISKY_ASSET_THRESHOLD_PERCENTAGE = 80 * PRECISION;

    uint256 public constant MINIMUM_COST_PERCENTAGE = 2 * PRECISION;

    uint256 public constant MINIMUM_INSURANCE_COST = 10 * DECIMALS; // 10 DAI (10 * 10**18)

    uint256 public constant LOW_RISK_MAX_PERCENT_PREMIUM_COST = 10 * PRECISION;
    uint256 public constant LOW_RISK_MAX_PERCENT_PREMIUM_COST_100_UTILIZATION = 50 * PRECISION;

    uint256 public constant HIGH_RISK_MAX_PERCENT_PREMIUM_COST = 25 * PRECISION;
    uint256 public constant HIGH_RISK_MAX_PERCENT_PREMIUM_COST_100_UTILIZATION = 100 * PRECISION;

    function calculateWhenNotRisky(
        uint256 _utilizationRatioPercentage,
        uint256 _maxPercentPremiumCost
    ) private pure returns (uint256) {
        // % CoC = UR*URRp*TMCC
        return
            (_utilizationRatioPercentage.mul(_maxPercentPremiumCost)).div(
                RISKY_ASSET_THRESHOLD_PERCENTAGE
            );
    }

    function calculateWhenIsRisky(
        uint256 _utilizationRatioPercentage,
        uint256 _maxPercentPremiumCost,
        uint256 _maxPercentPremiumCost100Utilization
    ) private pure returns (uint256) {
        // %CoC =  TMCC+(UR-URRp100%-URRp)*(MCC-TMCC)
        uint256 riskyRelation =
            (PRECISION.mul(_utilizationRatioPercentage.sub(RISKY_ASSET_THRESHOLD_PERCENTAGE))).div(
                (PERCENTAGE_100.sub(RISKY_ASSET_THRESHOLD_PERCENTAGE))
            );

        // %CoC =  TMCC+(riskyRelation*(MCC-TMCC))
        return
            _maxPercentPremiumCost.add(
                (
                    riskyRelation.mul(
                        _maxPercentPremiumCost100Utilization.sub(_maxPercentPremiumCost)
                    )
                )
                    .div(PRECISION)
            );
    }

    function getQuotePredefined(
        uint256 _durationSeconds,
        uint256 _tokens,
        uint256 _totalCoverTokens,
        uint256 _totalLiquidity,
        bool _safePolicyBook
    ) external pure override returns (uint256) {
        return
            _getQuote(
                _durationSeconds,
                _tokens,
                _totalCoverTokens,
                _totalLiquidity,
                _safePolicyBook
            );
    }

    function getQuote(
        uint256 _durationSeconds,
        uint256 _tokens,
        address _policyBookAddr
    ) external view override returns (uint256) {
        return
            _getQuote(
                _durationSeconds,
                _tokens,
                IPolicyBook(_policyBookAddr).totalCoverTokens(),
                IPolicyBook(_policyBookAddr).totalLiquidity(),
                IPolicyBook(_policyBookAddr).whitelisted()
            );
    }

    function _getQuote(
        uint256 _durationSeconds,
        uint256 _tokens,
        uint256 _totalCoverTokens,
        uint256 _totalLiquidity,
        bool _safePolicyBook
    ) internal pure returns (uint256) {
        require(
            _durationSeconds > 0 && _durationSeconds <= SECONDS_IN_THE_YEAR,
            "PolicyQuote: Invalid duration"
        );
        require(_tokens > 0, "PolicyQuote: Invalid tokens amount");
        require(
            _totalCoverTokens.add(_tokens) <= _totalLiquidity,
            "PolicyQuote: Requiring more than there exists"
        );

        uint256 utilizationRatioPercentage =
            ((_totalCoverTokens.add(_tokens)).mul(PERCENTAGE_100)).div(_totalLiquidity);

        uint256 annualInsuranceCostPercentage;

        uint256 maxPercentPremiumCost = HIGH_RISK_MAX_PERCENT_PREMIUM_COST;
        uint256 maxPercentPremiumCost100Utilization =
            HIGH_RISK_MAX_PERCENT_PREMIUM_COST_100_UTILIZATION;

        if (_safePolicyBook) {
            maxPercentPremiumCost = LOW_RISK_MAX_PERCENT_PREMIUM_COST;
            maxPercentPremiumCost100Utilization = LOW_RISK_MAX_PERCENT_PREMIUM_COST_100_UTILIZATION;
        }

        if (utilizationRatioPercentage < RISKY_ASSET_THRESHOLD_PERCENTAGE) {
            annualInsuranceCostPercentage = calculateWhenNotRisky(
                utilizationRatioPercentage,
                maxPercentPremiumCost
            );
        } else {
            annualInsuranceCostPercentage = calculateWhenIsRisky(
                utilizationRatioPercentage,
                maxPercentPremiumCost,
                maxPercentPremiumCost100Utilization
            );
        }

        // %CoC  final =max{% Col, MC}
        annualInsuranceCostPercentage = Math.max(
            annualInsuranceCostPercentage,
            MINIMUM_COST_PERCENTAGE
        );

        // $PoC   = the size of the coverage *%CoC  final
        uint256 actualInsuranceCostPercentage =
            (_durationSeconds.mul(annualInsuranceCostPercentage)).div(SECONDS_IN_THE_YEAR);

        return
            Math.max(
                (_tokens.mul(actualInsuranceCostPercentage)).div(PERCENTAGE_100),
                MINIMUM_INSURANCE_COST
            );
    }
}
