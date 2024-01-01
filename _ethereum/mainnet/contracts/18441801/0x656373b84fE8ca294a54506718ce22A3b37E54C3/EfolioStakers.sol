// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.19;

interface IEStake {
    function stakedLength() external view returns (uint256);
    function getTop(uint256 k) external view returns (address[] memory);
    function staked(address wallet) external view returns (uint256);
}

contract EFOLIOStakers {
    IEStake public estake;

    struct Staker {
        address addr;
        uint256 amount;
    }

    constructor(address stakeAddress) {
        estake = IEStake(stakeAddress);
    }

    function getStakers() public view returns (Staker[] memory) {
        uint256 length = estake.stakedLength();
        address[] memory stakersTop = estake.getTop(length);
        Staker[] memory stakers = new Staker[](length);
        for (uint256 index = 0; index < stakersTop.length; index++) {
            stakers[index] = Staker({addr: stakersTop[index], amount: estake.staked(stakersTop[index])});
        }
        return stakers;
    }
}