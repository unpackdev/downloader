// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IMasterChef {
    function totalAllocPoint() external view returns (uint256);
    function poolLength() external view returns (uint256);
    function poolInfo(uint256 nr) external view returns (address, uint256, uint256, uint256);
    function pendingSushi(uint256 nr, address who) external view returns (uint256);
}

contract BoringSushiPending
{
    struct PoolsInfo {
        uint256 totalAllocPoint;
        uint256 poolLength;
    }

    struct PoolInfo {
        uint256 pid;
        address lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. SUSHIs to distribute per block.
        uint256 pendingSushi;
    }
    
    IMasterChef chef = IMasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd); // Mainnet
    //IMasterChef chef = IMasterChef(0xFF281cEF43111A83f09C656734Fa03E6375d432A); // Ropsten
    
    function getPendingSushi(address who, uint256[] calldata pids) public view returns(PoolsInfo memory, PoolInfo[] memory) {
        PoolsInfo memory info;
        info.totalAllocPoint = chef.totalAllocPoint();
        uint256 poolLength = chef.poolLength();
        info.poolLength = poolLength;
        
        PoolInfo[] memory pools = new PoolInfo[](pids.length);

        for (uint256 i = 0; i < pids.length; i++) {
            pools[i].pid = pids[i];
            (address lpToken, uint256 allocPoint,,) = chef.poolInfo(pids[i]);
            pools[i].lpToken = lpToken;
            pools[i].allocPoint = allocPoint;
            pools[i].pendingSushi = chef.pendingSushi(pids[i],who);
        }
        return (info, pools);
    }
}

