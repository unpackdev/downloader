// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IStakedDVF {
    function balanceOf(address account) external view returns (uint);
    function transfer(address dst, uint rawAmount) external returns (bool);
    function enter(uint256 _amount) external returns (bool);
    function leave(uint256 _share) external returns (bool);
    function takeVoteSnapshotAtBlock() external returns (uint);
    function balanceOfAt(address account, uint256 snapshotId) external view returns (uint);
}
