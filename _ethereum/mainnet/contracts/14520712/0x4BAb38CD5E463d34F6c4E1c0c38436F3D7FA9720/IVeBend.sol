// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IVeBend {
    struct Point {
        int256 bias;
        int256 slope;
        uint256 ts;
        uint256 blk;
    }

    struct LockedBalance {
        int256 amount;
        uint256 end;
    }

    function createLockFor(
        address _beneficiary,
        uint256 _value,
        uint256 _unlockTime
    ) external;

    function increaseAmountFor(address _beneficiary, uint256 _value) external;

    function getLocked(address _addr)
        external
        view
        returns (LockedBalance memory);

    function balanceOf(address _addr) external view returns (uint256);
}
