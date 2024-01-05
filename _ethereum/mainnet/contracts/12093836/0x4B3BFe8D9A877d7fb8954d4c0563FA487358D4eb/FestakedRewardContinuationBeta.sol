pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";
import "./FestakedRewardContinuation.sol";

/**
 * A beta version of FestakedRewardContinuation with ability of sweeping the rewards
 * in case something went wrong.
 * NOTE: Once you sweep rewards to owner, do NOT use the contract any more.
 */
contract FestakedRewardContinuationBeta is FestakedRewardContinuation, Ownable {
    constructor(
        address targetStake_,
        address tokenAddress_,
        address rewardTokenAddress_) FestakedRewardContinuation(
            targetStake_, tokenAddress_, rewardTokenAddress_) public {}
    bool nuked = false;

    function initialize() public override returns (bool) {
        require(!nuked, "FRCB: Already nuked");
        return FestakedRewardContinuation.initialize();
    }

    function sweepToOwner() onlyOwner() external {
        uint256 balance = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(owner(), balance);
        initialSync = false; // Make sure contract cannot be used any more.
        nuked = true;
    }
}