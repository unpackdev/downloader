//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface ILynxStaking {
    struct Stake {
        uint256 depositAmount;
        uint256 startStake;
        uint256 rewardEnd;
        uint256 posIndex;
        uint256 lockedRewards;
        bool set;
    }

    struct AprConfig {
        bool setup; // This is a flag to indicate if the APR has been set up
        uint256 apr; // This is the APR for the staking - this has to be in the format XX_00 since there are 2 decimals in the APR value;
        uint256 duration; // This is the duration in weeks of when the staking should end
    }

    /**
     * Deposit tokens in the Staking pool and start earning rewards while the tokens are locked.
     * @param amount The amount of LYNX to deposit
     * @dev if the user is already staked in, claim the current rewards and add the new deposit to the existing one, then relock the tokens for duration.
     */
    function deposit(uint amount) external;

    /**
     * Withdraw tokens from the Staking pool along with the rewards earned.
     */
    function withdraw() external;

    /**
     * Gives the current reward amount for the user.
     * @param user The address of the user to check
     * @return The amount of LYNX the user has been rewarded with
     * @dev If the user is staked for longer than the lock amount, no additional rewards are given.
     */
    function currentRewards(address user) external view returns (uint256);

    event Deposit(
        address indexed user,
        uint256 amount,
        uint256 duration,
        uint256 rewardEnd
    );

    event ClaimRewards(address indexed user, uint256 amount);
    event LockedRewards(address indexed user, uint256 amount);
}
