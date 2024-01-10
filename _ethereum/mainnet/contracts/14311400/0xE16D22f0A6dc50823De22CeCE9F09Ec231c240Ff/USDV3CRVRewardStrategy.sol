// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC20.sol";
import "./Auth.sol";
import "./SafeTransferLib.sol";
import "./FixedPointMathLib.sol";
import "./Strategy.sol";
import "./Vault.sol";

interface IRewards {
    function rewardsToken() external view returns (address);
    function exit() external;
    function getReward() external;
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function earned(address director) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address director) external view returns (uint256);
}
library Math {
    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }
}

import "./StrategyBaseV1.sol";

contract USDV3CRVRewardStrategy is StrategyBaseV1 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    IRewards public immutable REWARDS;

    constructor(
        ERC20 UNDERLYING_,
        address GOVERNANCE_,
        Authority AUTHORITY_,
        IRewards REWARDS_,
        Gauge GAUGE_,
        Bribe BRIBE_
    ) Auth(GOVERNANCE_, AUTHORITY_)
    ERC20("USDV3CRVRewardStrategy", "aUSDV3CRVRewardStrategy", 18) {
        UNDERLYING = UNDERLYING_; //vader
        BASE_UNIT = 10e18;
        REWARDS = REWARDS_;
        BRIBE = BRIBE_;
        GAUGE = GAUGE_;
        UNDERLYING.safeApprove(address(REWARDS_), type(uint256).max);
        bribeRate = 10; //10% to bribe
        gaugeRate = 10; //10% to gauge
    }

    function isCEther() external pure override returns (bool) {
        return false;
    }

    function underlying() external view override returns (ERC20) {
        return UNDERLYING;
    }

    function mint(uint256 amount) external requiresAuth override returns (uint256) {
        _mint(msg.sender, amount.fdiv(_exchangeRate(), BASE_UNIT));
        UNDERLYING.safeTransferFrom(msg.sender, address(this), amount);
        _stakeUnderlying(UNDERLYING.balanceOf(address(this)));
        return 0;
    }

    function redeemUnderlying(uint256 amount) external override returns (uint256) {
        _burn(msg.sender, amount.fdiv(_exchangeRate(), BASE_UNIT));

        if (UNDERLYING.balanceOf(address(this)) < amount) {
            uint leaveAmount = amount - UNDERLYING.balanceOf(address(this));
            _unstakeUnderlying(leaveAmount);
        }
        UNDERLYING.safeTransfer(msg.sender, amount);

        return 0;
    }

    function balanceOfUnderlying(address user) external view override returns (uint256) {
        return balanceOf[user].fmul(_exchangeRate(), BASE_UNIT);
    }

    /* //////////////////////////////////////////////////////////////
                            INTERNAL LOGIC
    ///////////////////////////////////////////////////////////// */

    ERC20 internal immutable UNDERLYING;

    uint256 internal immutable BASE_UNIT;

    function _stakeUnderlying(uint amount) internal {
        REWARDS.stake(amount);
    }

    function _unstakeUnderlying(uint amount) internal {
        REWARDS.withdraw(amount);
    }

    function _computeStakedUnderlying() internal view returns (uint256) {
        return REWARDS.balanceOf(address(this));
    }

    function _exchangeRate() internal view returns (uint256) {
        uint256 cTokenSupply = totalSupply;

        if (cTokenSupply == 0) return BASE_UNIT;
        uint underlyingBalance;
        uint stakedBalance = _computeStakedUnderlying();
    unchecked {
        underlyingBalance = UNDERLYING.balanceOf(address(this)) + stakedBalance;
    }
        return underlyingBalance.fdiv(cTokenSupply, BASE_UNIT);
    }

    function hit() external {
        //get rewards
        REWARDS.getReward();

        ERC20 rewardToken = ERC20(REWARDS.rewardsToken());

        uint harvest = rewardToken.balanceOf(address(this));
        uint bribePayment = _payBribe(rewardToken, harvest);
        uint gaugePayment = _payGauge(rewardToken, harvest);
        //calc treasuryDeposit
        uint treasuryDeposit = harvest - bribePayment - gaugePayment;
        //transfer to owner(treasury)
        rewardToken.transfer(owner, treasuryDeposit);
    }
}
