// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface ITracker{
    // view functions
    function claimWait() external view returns(uint256);
    function owner() external view returns (address);
    function isExcludedFromDividends(address account) external view returns(bool);
    function totalDividendsDistributed() external view returns(uint256);
    function withdrawableDividendOf(address account) external view returns(uint256);
    function getLastProcessedIndex() external view returns(uint256);
    function getNumberOfTokenHolders() external view returns(uint256);
    function getAccount(address _account)
        external view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable);
    function getAccountAtIndex(uint256 _index)
        external view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable);
    // state functions
    function excludeFromDividends(address account, bool exclude) external;
    function updateClaimWait(uint256 newClaimWait) external;
    function updateMinimumForDividends(uint256 amount) external;
    function setBalance(address payable account, uint256 newBalance) external;
    function process(uint256 gas) external returns (uint256, uint256, uint256);
    function processAccount(address payable account) external;
}