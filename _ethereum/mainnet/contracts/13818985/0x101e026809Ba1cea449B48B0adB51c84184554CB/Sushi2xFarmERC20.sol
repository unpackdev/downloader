// SPDX-License-Identifier: LGPL-3.0-or-later
pragma abicoder v2;
pragma solidity ^0.8.7;

contract Sushi2xFarmERC20 {
    address public masterChefAddress;
    uint256 public poolId;
    
    constructor(address _masterChefAddress, uint256 _poolId) {
        masterChefAddress = _masterChefAddress;
        poolId = _poolId;
    }

    function balanceOf(address _user)
        public
        view
        returns (uint256 amount)
    {
        (amount,) = MasterChefV2(masterChefAddress).userInfo(poolId, _user);
    }
}

interface MasterChefV2 {
    function userInfo(uint256 _pid, address _user) external view returns (uint256 amount, uint256 rewardDebt);
}