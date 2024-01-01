// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface ITokenLocker {
    struct LockData {
        uint amount;
        uint weeksToUnlock;
    }

    function lock(address _account, uint256 _amount, uint256 _weeks) external returns (bool);
    function withdrawExpiredLocks(uint256 _weeks) external returns (bool);
    function withdrawWithPenalty(uint amountToWithdraw) external returns (uint);

    function getAccountBalances(address account) external view returns (uint256 locked, uint256 unlocked);
    function getAccountActiveLocks(
        address account,
        uint minWeeks
    ) external view returns (LockData[] memory lockData, uint frozenAmount);

    function getAccountWeightAt(address account, uint week) external view returns (uint256);

    function getTotalWeightAt(uint week) external view returns (uint256);

    function getWithdrawWithPenaltyAmounts(address account, uint amountToWithdraw) external view returns (uint amountWithdrawn, uint penaltyAmountPaid);

    function lockToTokenRatio() external view returns (uint256);

    function freeze() external;
}
