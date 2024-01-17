// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IVeToken {

    struct Point {
        int128 bias;
        int128 slope; // - dweight / dt
        uint256 ts;
        uint256 blk; // block
    }
    function pointHistory(uint256 index) external view returns(Point memory);

    function createLockFor(address addr, uint256 amount, uint256 lockEnd) external;

    function depositFor(address _addr, uint256 _value) external;

    function increaseAmountFor(address _account, uint256 _value) external;

    function increaseUnlockTimeFor(address _account, uint256 _unlockTime) external;

    function getLastUserSlope(address addr) external view returns (int128);

    function lockedEnd(address addr) external view returns (uint256);

    function lockedAmount(address addr) external view returns (uint256);

    function userPointEpoch(address addr) external view returns (uint256);

    function userPointHistoryTs(address addr, uint256 epoch)
        external
        view
        returns (uint256);

    function balanceOfAt(address addr, uint256 _block)
        external
        view
        returns (uint256);

    function balanceOf(address addr) external view returns (uint256);

    function balanceOf(address addr, uint256 timestamp)
        external
        view
        returns (uint256);

    function totalSupply() external view returns (uint256);

    function lockedSupply() external view returns (uint256);

    function lockStarts(address addr) external view returns (uint256);

    function totalSupplyAt(uint256 _block) external view returns (uint256);

    function MAXTIME() external view returns (uint256);

    function WEEK() external view returns (uint256);
}
