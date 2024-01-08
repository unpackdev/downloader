// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

struct Point{
    int128 bias;
    int128 slope;
    uint256 ts;
    uint256 blk;
}

struct LockedBalance{
    int128 amount;
    uint256 end;
}

interface IVMochi {
    function locked(address _user) external view returns(LockedBalance memory);
    function depositFor(address _user, uint256 _amount) external;
    function balanceOf(address _user) external view returns(uint256);
}
