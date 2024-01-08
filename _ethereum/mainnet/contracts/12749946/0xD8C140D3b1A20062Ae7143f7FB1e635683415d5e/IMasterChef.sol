pragma solidity 0.8.0;

// SPDX-License-Identifier: MIT


interface IMasterChef {
    function deposit(uint256, uint256) external;
    function harvest(uint256) external;
    function poolLength() external returns (uint256);
    function userInfo(uint256, address) external returns(uint256, uint256);
    function totalAllocPoint() external view returns(uint256);
    function pendingTaco() external view returns(uint256);
    function poolInfo(uint256) external returns(address, uint256, uint256, uint256);
    function setMigrator(address) external;
    function migrate(uint256) external;
    function massUpdatePools() external;
}
