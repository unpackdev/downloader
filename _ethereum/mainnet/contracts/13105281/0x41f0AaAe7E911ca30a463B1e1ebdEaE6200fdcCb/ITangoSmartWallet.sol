// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface ITangoSmartWallet { 
    function owner()  external returns(address);
    function initialize(address _owner, address _lp, address _pool) external;
    function stake(address _pool, uint256 _pid) external;
    function stakedBalance() external returns(uint256);
    function withdraw(address _pool, uint256 _amount) external;
    function claimReward(address) external returns (uint256, uint256);
}