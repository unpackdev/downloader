// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ILIMC {

    event BlacklistStatusChanged(address indexed account, bool isBlacklistedNow);

    event TransferLocked(address indexed from, address indexed to, uint256 amount);

    event ApprovalLocked(address indexed owner, address indexed spender, uint256 index, uint256 amount);

    function balanceOfSum(address account) external view returns (uint256);

    function balanceOfLocked(address account) external view returns (uint256);

    function userLocksLength(address account) external view returns (uint256);

    function transferLocked(address to, uint256 index, uint256 amount) external;

    function transferFromLocked(address from, address to, uint256 index, uint256 amount) external;

    function approveLocked(address to, uint256 index, uint256 amount) external;

    function increaseAllowanceLocked(address to, uint256 index, uint256 amount) external;

    function decreaseAllowanceLocked(address to, uint256 index, uint256 amount) external;

    function pause() external;

    function unpause() external;

    function addToBlacklist(address account) external;

    function removeFromBlacklist(address account) external;

    function mint(address account, uint256 amount, uint256 lockTime) external;

    function unlock(address account, uint256 numberOfLocks) external;
}