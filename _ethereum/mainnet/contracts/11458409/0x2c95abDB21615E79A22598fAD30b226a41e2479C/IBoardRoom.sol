// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


interface IBoardRoom {
    function exit() external;
    function claimReward() external;
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function earned(address director) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address director) external view returns (uint256);
}
