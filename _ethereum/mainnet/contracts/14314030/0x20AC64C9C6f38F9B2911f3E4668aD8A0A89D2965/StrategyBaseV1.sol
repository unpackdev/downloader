// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC20.sol";
import "./Auth.sol";
import "./SafeTransferLib.sol";
import "./FixedPointMathLib.sol";
import "./Strategy.sol";
import "./Bribe.sol";
import "./Gauge.sol";

abstract contract StrategyBaseV1 is Auth, ERC20, ERC20Strategy {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;


    Bribe public BRIBE;
    Gauge public GAUGE;

    uint public bribeRate = 0;
    uint public bribeRateBase = 100;

    uint public gaugeRate = 0;
    uint public gaugeRateBase = 100;

    event DevWithdraw(address token, address to);
    event BribePaid(uint payment);

    function setGaugeBribe(Gauge newGauge_, Bribe newBribe_) external requiresAuth {
        GAUGE = newGauge_;
        BRIBE = newBribe_;
    }

    function setRates(uint newGaugeRate_, uint newBribeRate_) external requiresAuth {
        gaugeRate = newGaugeRate_;
        bribeRate = newBribeRate_;
    }

    function setBaseRates(uint newGaugeRateBase_, uint newBribeRateBase_) external requiresAuth {
        gaugeRateBase = newGaugeRateBase_;
        bribeRateBase = newBribeRateBase_;
    }


    function _payBribe(ERC20 bribeToken, uint profit) internal returns (uint bAmount){
        if (profit == uint(0) || bribeRateBase == uint(0) || bribeRate == uint(0)) return uint(0);
        bAmount = profit * bribeRate / bribeRateBase;
        bribeToken.safeApprove(address(BRIBE), bAmount);
        BRIBE.notifyRewardAmount(address(bribeToken), bAmount);
    }

    function _payGauge(ERC20 rewardToken, uint profit) internal returns (uint rAmount){
        if (profit == uint(0) || gaugeRateBase == uint(0) || gaugeRate == uint(0)) return uint(0);
        rAmount = profit * gaugeRate / gaugeRateBase;
        rewardToken.safeApprove(address(GAUGE), rAmount);
        GAUGE.notifyRewardAmount(address(rewardToken), rAmount);
    }

    function __emergencyExit() virtual external requiresAuth {}

    //requires governance to do this, in the event assets are stuck in the contract
    function emergencyWithdrawalToken(ERC20 token) virtual external requiresAuth {
        //send the tokens to the Vault's Owner so they can be given back to the depositors as
        //something has gone wrong with the strategy
        token.safeTransfer(owner, token.balanceOf(address(this)));
        emit DevWithdraw(address(token), owner);
    }

}
