// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


interface ITokenDividendPool {
    /// @dev Claim batch
    function claimBatch(address[] calldata _tokens) external;

    /// @dev Claim
    function claim(address _token) external;

    /// @dev Claim up to `_timestamp`
    function claimUpTo(address _token, uint256 _endSnapshotIndex) external;

    /// @dev Distribute
    function distribute(address _token, uint256 _amount) external;
    
    /// @dev getAvailableClaims
    function getAvailableClaims(address _account) external view returns (address[] memory claimableTokens, uint256[] memory claimableAmounts);

    /// @dev Returns claimable amount
    function claimable(address _token, address _account) external view returns (uint256);
    
    /// @dev Returns claimable amount from `_timeStart` to `_timeEnd`
    function claimableUpTo(address _token, address _account, uint256 _endSnapshotIndex) external view returns (uint256);

    /// @dev Returns the total distribution amount for `_token`
    function totalDistribution(address _token) external view returns (uint256);
}