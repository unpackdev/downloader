//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Staking Pool interface
/// @author Ankit Parashar
interface IStakingPool {
    
    function slash(uint256 amount) external;

    function numOfValidatorAllowed(address usr) external returns (uint256);

    function claimAndUpdateRewardDebt(address usr) external;

    function updateRewardPerValidator(uint256 newReward) external;

}