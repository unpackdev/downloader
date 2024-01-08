// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./SafeMath.sol";
import "./Math.sol";

import "./IPolicyBook.sol";
import "./IPolicyQuote.sol";
import "./IPolicyBookFacade.sol";

import "./AbstractDependant.sol";

import "./Globals.sol";

contract PolicyQuote is IPolicyQuote, AbstractDependant {
    using Math for uint256;
    using SafeMath for uint256;

    // new state post v2 deployment
    address public policyBookAdminAddress;
    // URRp Utilization ration for pricing model when the assets is considered risky, %;
    uint256 public riskyAssetThresholdPercentage;
    // MC – minimum cost of cover (Premium) %
    uint256 public minimumCostPercentage;
    uint256 public minimumInsuranceCost;
    // TMCI target maximum cost of cover when the asset is not considered risky %
    uint256 public lowRiskMaxPercentPremiumCost;
    uint256 public lowRiskMaxPercentPremiumCost100Utilization;
    // TMCI target maximum cost of cover when the asset is considered risky %
    uint256 public highRiskMaxPercentPremiumCost;
    uint256 public highRiskMaxPercentPremiumCost100Utilization;

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        policyBookAdminAddress = _contractsRegistry.getPolicyBookAdminContract();
    }

    function calculateWhenNotRisky(
        uint256 _utilizationRatioPercentage,
        uint256 _maxPercentPremiumCost
    ) private view returns (uint256) {
        // % CoC = UR*URRp*TMCC
        return
            (_utilizationRatioPercentage.mul(_maxPercentPremiumCost)).div(
                riskyAssetThresholdPercentage
            );
    }

    function calculateWhenIsRisky(
        uint256 _utilizationRatioPercentage,
        uint256 _maxPercentPremiumCost,
        uint256 _maxPercentPremiumCost100Utilization
    ) private view returns (uint256) {
        // %CoC =  TMCC+(UR-URRp100%-URRp)*(MCC-TMCC)
        uint256 riskyRelation =
            (PRECISION.mul(_utilizationRatioPercentage.sub(riskyAssetThresholdPercentage))).div(
                (PERCENTAGE_100.sub(riskyAssetThresholdPercentage))
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
        uint256 _totalLeveragedLiquidity,
        bool _safePricingModel
    ) external view override returns (uint256, uint256) {
        return
            _getQuote(
                _durationSeconds,
                _tokens,
                _totalCoverTokens,
                _totalLiquidity,
                _totalLeveragedLiquidity,
                _safePricingModel
            );
    }

    function getQuote(
        uint256 _durationSeconds,
        uint256 _tokens,
        address _policyBookAddr
    ) external view override returns (uint256) {
        (uint256 price, ) =
            _getQuote(
                _durationSeconds,
                _tokens,
                IPolicyBook(_policyBookAddr).totalCoverTokens(),
                IPolicyBook(_policyBookAddr).totalLiquidity(),
                IPolicyBookFacade(address(IPolicyBook(_policyBookAddr).policyBookFacade()))
                    .totalLeveragedLiquidity(),
                IPolicyBookFacade(address(IPolicyBook(_policyBookAddr).policyBookFacade()))
                    .safePricingModel()
            );
        return price;
    }

    function _getQuote(
        uint256 _durationSeconds,
        uint256 _tokens,
        uint256 _totalCoverTokens,
        uint256 _totalLiquidity,
        uint256 _totalLeveragedLiquidity,
        bool _safePricingModel
    ) internal view returns (uint256 price, uint256 actualInsuranceCostPercentage) {
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
            ((_totalCoverTokens.add(_tokens)).mul(PERCENTAGE_100)).div(
                _totalLiquidity.add(_totalLeveragedLiquidity)
            );

        uint256 annualInsuranceCostPercentage;

        uint256 maxPercentPremiumCost = highRiskMaxPercentPremiumCost;

        uint256 maxPercentPremiumCost100Utilization = highRiskMaxPercentPremiumCost100Utilization;

        if (_safePricingModel) {
            maxPercentPremiumCost = lowRiskMaxPercentPremiumCost;
            maxPercentPremiumCost100Utilization = lowRiskMaxPercentPremiumCost100Utilization;
        }

        if (utilizationRatioPercentage < riskyAssetThresholdPercentage) {
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
            minimumCostPercentage
        );

        // $PoC   = the size of the coverage *%CoC  final
        actualInsuranceCostPercentage = (_durationSeconds.mul(annualInsuranceCostPercentage)).div(
            SECONDS_IN_THE_YEAR
        );

        price = Math.max(
            (_tokens.mul(actualInsuranceCostPercentage)).div(PERCENTAGE_100),
            minimumInsuranceCost
        );
    }

    ///@notice return min ur under the current pricing model
    ///@param _safePricingModel pricing model of the pool wethere it is safe or risky model
    function getMINUR(bool _safePricingModel) external view override returns (uint256 _minUR) {
        uint256 maxPercentPremiumCost = highRiskMaxPercentPremiumCost;

        if (_safePricingModel) {
            maxPercentPremiumCost = lowRiskMaxPercentPremiumCost;
        }

        _minUR = minimumCostPercentage.mul(riskyAssetThresholdPercentage).div(
            maxPercentPremiumCost
        );
    }

    /// @notice setup all pricing model varlues
    ///@param _riskyAssetThresholdPercentage URRp Utilization ration for pricing model when the assets is considered risky, %
    ///@param _minimumCostPercentage MC minimum cost of cover (Premium), %;
    ///@param _minimumInsuranceCost minimum cost of insurance (Premium) , (10**18)
    ///@param _lowRiskMaxPercentPremiumCost TMCI target maximum cost of cover when the asset is not considered risky (Premium)
    ///@param _lowRiskMaxPercentPremiumCost100Utilization MCI not risky
    ///@param _highRiskMaxPercentPremiumCost TMCI target maximum cost of cover when the asset is considered risky (Premium)
    ///@param _highRiskMaxPercentPremiumCost100Utilization MCI risky
    function setupPricingModel(
        uint256 _riskyAssetThresholdPercentage,
        uint256 _minimumCostPercentage,
        uint256 _minimumInsuranceCost,
        uint256 _lowRiskMaxPercentPremiumCost,
        uint256 _lowRiskMaxPercentPremiumCost100Utilization,
        uint256 _highRiskMaxPercentPremiumCost,
        uint256 _highRiskMaxPercentPremiumCost100Utilization
    ) external override {
        require(msg.sender == policyBookAdminAddress, "PQ: Not a PBA");

        riskyAssetThresholdPercentage = _riskyAssetThresholdPercentage;
        minimumCostPercentage = _minimumCostPercentage;
        minimumInsuranceCost = _minimumInsuranceCost;
        lowRiskMaxPercentPremiumCost = _lowRiskMaxPercentPremiumCost;
        lowRiskMaxPercentPremiumCost100Utilization = _lowRiskMaxPercentPremiumCost100Utilization;
        highRiskMaxPercentPremiumCost = _highRiskMaxPercentPremiumCost;
        highRiskMaxPercentPremiumCost100Utilization = _highRiskMaxPercentPremiumCost100Utilization;
    }
}
