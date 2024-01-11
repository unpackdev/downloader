//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;


/// @title IRewardProgramVaultAction
interface IRewardProgramVaultAction {

    /// ####### only admin ##########

    /// @dev initialization function . Set claim information.
    /// @param _totalAllocatedAmount total allocated amount
    /// @param _claimCounts total claim Counts
    /// @param _claimTimes claimTime must be in ascending order from smallest to largest
    /// @param _claimAmounts The sum of _claimAmounts must equal _totalAllocatedAmount .
    function initialize(
        uint256 _totalAllocatedAmount,
        uint256 _claimCounts,
        uint256[] calldata _claimTimes,
        uint256[] calldata _claimAmounts

    ) external ;

    /// @dev Set the project token address.
    /// @param _token project token address.
    function changeToken(address _token) external ;

    /// @dev Set the Staker address.
    /// @param _staker Staker address.
    function changeStaker(address _staker) external ;

    /// @dev Set the pool address.
    /// @param _pool pool address.
    function changePool(address _pool) external ;

    /// @dev Set parameters.
    /// @param _startWaitTime  the program startTime is determined added the current block time and _startWaitTime seconds.
    function changeSetting(uint256 _startWaitTime) external;



    /// ####### anyone can use ##########


    /// @dev get trhe current round
    /// @return round round
    function currentRound() external view returns (uint256 round) ;

    /// @dev get about claim related information
    /// @return _totalClaimCounts total number of claims
    /// @return _claimTimes Claimable start time of each round
    /// @return _claimAmounts Amount allocated for each round of claims
    /// @return _totalClaimsAmount Total Claimed Quantity
    function getClaimInfo() external view returns (
        uint256 _totalClaimCounts,
        uint256[] memory _claimTimes,
        uint256[] memory _claimAmounts,
        uint256 _totalClaimsAmount
        )  ;


    /// @dev Amount of project tokens at round available
    /// @param _round round
    /// @return amount availableUseAmount
    function availableUseAmount(uint256 _round) external view returns (uint256 amount) ;

    /// @dev create reward program
    function createProgram() external;

    /// @dev end reward program
    /// @param _index _index
    /// @param tokenIds need to unstake
    function IncentiveEnded(uint256 _index, uint256[] memory tokenIds) external;

}
