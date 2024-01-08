// SPDX-License-Identifier: ISC

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";
import "./IALPHAStaking.sol";
import "./IStakingProxy.sol";

contract StakingProxy is IStakingProxy, Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // The alpha contracts
    IAlphaStaking private alphaStaking;

    function initialize(address _alphaStaking) public override initializer {
        __Ownable_init_unchained();

        alphaStaking = IAlphaStaking(_alphaStaking);

        // Approve ALPHA for the staking contract
        IERC20(alphaStaking.alpha()).safeApprove(address(alphaStaking), 2**256 - 1);
    }

    function getTotalStaked() public view override returns (uint256) {
        return alphaStaking.getStakeValue(address(this));
    }

    function getUnbondingAmount() public view override returns (uint256) {
        return _stakingShareToAmount(alphaStaking.users(address(this)).unbondShare);
    }

    function getLastUnbondingTimestamp() external view override returns (uint256) {
        return alphaStaking.users(address(this)).unbondTime;
    }

    function getWithdrawableAmount() external view override returns (uint256) {
        // To withdraw an unbonding request must have been made and must be the right time or
        if (
            alphaStaking.users(address(this)).status == alphaStaking.STATUS_UNBONDING() &&
            block.timestamp >= alphaStaking.users(address(this)).unbondTime.add(alphaStaking.UNBONDING_DURATION()) &&
            block.timestamp <
            alphaStaking.users(address(this)).unbondTime.add(alphaStaking.UNBONDING_DURATION()).add(
                alphaStaking.WITHDRAW_DURATION()
            )
        ) {
            return getUnbondingAmount();
        } else {
            return 0;
        }
    }

    function isUnbonding() external view override returns (bool) {
        return alphaStaking.users(address(this)).status == alphaStaking.STATUS_UNBONDING();
    }

    function withdraw() external override onlyOwner returns (uint256) {
        // Withdraw unbonding amount
        alphaStaking.withdraw();

        uint256 balance = IERC20(alphaStaking.alpha()).balanceOf(address(this));

        // Send the claimed tokens plus any exttra tokens back to the caller (xALPHA)
        IERC20(alphaStaking.alpha()).safeTransfer(msg.sender, balance);

        return balance;
    }

    function stake(uint256 amount) external override onlyOwner {
        require(
            IERC20(alphaStaking.alpha()).balanceOf(address(this)) >= amount,
            "Staking amount greater than ALPHA balance"
        );

        alphaStaking.stake(amount);
    }

    function unbond() external override onlyOwner {
        // Unbond total staking share, will have no impact on staking rewards until amount is withdrawn
        alphaStaking.unbond(alphaStaking.users(address(this)).share);
    }

    function withdrawToken(address token) external override onlyOwner {
        require(IERC20(token).balanceOf(address(this)) > 0, "Zero token balance");
        IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function _stakingShareToAmount(uint256 share) internal view returns (uint256) {
        // If total alpha staked is 0, then so will total share. Check is made to avoid div by 0. This won't happen
        return
            alphaStaking.totalAlpha() == 0 ? 0 : (alphaStaking.totalAlpha()).mul(share).div(alphaStaking.totalShare());
    }
}
