pragma solidity 0.8.10;

interface IStakingMaster {
    /**
        @dev The struct containing all of a stakes data
     */
    struct Staking {
        uint256 investedAmount;
        uint256 stakeEndTime;
        uint256 interestRate;
        uint256 lastUpdate;
        bool compounded;
        // The amount they add in at the start, un-modified
        uint256 rawInvestedAmount;
        uint256 stakeStartTime;
        bool providerStake;
        uint256 released;
        bool poolRewardsClaimed;
        uint256 totalLocked;
    }

    /**
        @dev Returns a given user's total stake value across all the user's stakes, including all interest earnt up until now.
        @param _user The user to return the value for
        @return The users total stake value
     */
    function returnUsersTotalStakeValue(address _user)
        external
        view
        returns (uint256);

    /**
        @dev Creates a new stake for the user. It calculates their projected interest based on the parameters and stores it in a TokenVesting contract that vests their total amount over 2 weeks once their stake is complete. It also creates a struct containing all the relevant stake details.
        @param _amount The amount the user will be staking (in ether)
        @param _duration The duration of the stake (in months)
        @param _recipient The address of the user that will be receiving the stake rewards
     */
    function createStaking(
        uint256 _amount,
        uint256 _duration,
        address _recipient
    ) external;

    /**
        @dev Adds to a user's pre-existing stake. This can only be triggered by the Provider Contract, i.e; when a user is re-investing their rewards from the Provider Contract.
        @param _stakingAddress The address of the stake
        @param _amount The additional amount to stake
     */
    function addToStake(address _stakingAddress, uint256 _amount) external;

    /**
        @dev Claim rewards for a given stake. This releases the allowed amount from the Vesting contract and also returns them pool rewards. This can only be called when a stake is complete and by the _recipient of the stake only.
        @param _stakingAddress The address of the stake
     */
    function claimRewards(address _stakingAddress) external;

    /**
        @dev Close the given stake, this can only happen when a stake is incomplete and User wishes to close the stake early. This function calculates their penalised amount for withdrawing early and stores it in the StakingMaster contract as the pool reward. It then transfers their allowed amount back to the user.
        @param _stakingAddress The address of the stake
     */
    function closeStake(address _stakingAddress) external;

    /* Helpers */

    /**
        @dev Returns a given stakes state
        @param _stakingAddress The address of the stake

        @return currentStakeValue The current value of the stake, including interest up until now
        @return stakeEndTime When the stake will finish
        @return interestRate The interest rate of the stake
        @return lastUpdate When the stake last had value added to it, or when it was created (if no additional value has been added to the stake)
        @return compounding Whether the stake is compounding
        @return rawInvestedAmount The User's invested amount (excluding interest)
        @return stakeStartTime When the stake was created
     */
    function returnStakeState(address _stakingAddress)
        external
        view
        returns (
            uint256 currentStakeValue,
            uint256 stakeEndTime,
            uint256 interestRate,
            uint256 lastUpdate,
            bool compounding,
            uint256 rawInvestedAmount,
            uint256 stakeStartTime
        );

    /**
        @dev Returns a given user's stakes
        @param _user The user to return stakes for

        @return usersStakes An array containing the addreses of all the user's created stakes
     */
    function returnUsersStakes(address _user)
        external
        view
        returns (address[] memory usersStakes);

    /**
        @dev Returns the given stake value corresponding to the stake address

        @return _stakingAddress The staking address to return the value for
     */
    function returnCurrentStakeValue(address _stakingAddress)
        external
        view
        returns (uint256);

    /**
        @dev Returns a user's staking address if the stake is in progress and was created by the provider contract. Function intended to be called by the provider contract when the user is claiming rewards and intending them to be sent to a Staking contract
        @param _user The user to return valid stakes for

        @return The valid stake address
     */
    function returnValidUsersProviderStake(address _user)
        external
        view
        returns (address);

    /**
        @dev Returns a stakes claimable rewards, 

        @param _stakingAddress The stake to return the claimable rewards for

        @return The claimable amount
     */
    function returnStakesClaimableRewards(address _stakingAddress)
        external
        view
        returns (uint256);

    /**
        @dev Returns a stakes claimable pool rewards

        @param _stakingAddress The stake to return the claimable pool rewards for

        @return The claimable pool reward amount
     */
    function returnStakesClaimablePoolRewards(address _stakingAddress)
        external
        view
        returns (uint256);
}
