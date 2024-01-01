

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IGemLock {
    function lock(
        address owner,
        address token,
        bool isLpToken,
        uint256 amount,
        uint256 unlockDate
    ) external returns (uint256 lockId);

    function vestingLock(
        address owner,
        address token,
        bool isLpToken,
        uint256 amount,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps
    ) external returns (uint256 lockId);

    function multipleVestingLock(
        address[] calldata owners,
        uint256[] calldata amounts,
        bool isLpToken,
        address token,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps
    ) external returns (uint256[] memory);

    function unlock(uint256 lockId) external;

    function editLock(
        uint256 lockId,
        uint256 newAmount,
        uint256 newUnlockDate
    ) external;
}
