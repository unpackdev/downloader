// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface StakingContract {
    function getStakedCount(address account)
        external
        view
        returns (uint256);
}

contract CollabFaker {
    StakingContract public stakingContract =
        StakingContract(0x60d4a9CB8aDCE7Ae0a8d4F110D31ee6F5e56e996);

    function balanceOf(address owner) external view returns (uint256 balance) {
        return stakingContract.getStakedCount(owner);
    }
}