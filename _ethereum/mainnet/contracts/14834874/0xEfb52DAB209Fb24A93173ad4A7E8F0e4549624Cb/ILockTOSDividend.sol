// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;


interface ILockTOSDividend {
    /// @dev Claim
    function claim(address _token) external;

    /// @dev Claim up to `_timestamp`
    function claimUpTo(address _token, uint256 _timestamp) external;

    /// @dev Distribute
    function distribute(address _token, uint256 _amount) external;
    
    /// @dev Redistribute
    function redistribute(address _token, uint256 _weeklyEpoch) external;

    /// @dev Get weekly epoch for `_timestamp`
    function getWeeklyEpoch(uint256 _timestamp) external view returns (uint256);

    /// @dev Get current weekly epoch
    function getCurrentWeeklyEpoch() external view returns (uint256);

    /// @dev Returns tokens per week at `_timestamp`
    function tokensPerWeekAt(address _token, uint256 _timestamp)
        external
        view
        returns (uint256);

    /// @dev Returns the last epoch claimed for `_lockId`
    function claimStartWeeklyEpoch(address _token, uint256 _lockId)
        external
        view
        returns (uint256);

    /// @dev Returns claimable amount
    function claimable(address _token) external view returns (uint256);
    
    /// @dev Returns claimable amount from `_timeStart` to `_timeEnd`
    function claimableForPeriod(address _token, uint256 _timeStart, uint256 _timeEnd) external view returns (uint256);
}