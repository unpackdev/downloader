//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IStakingContract {
    function restakeOnSell(uint256 id, address newOwner) external;

    function stake(uint256[] memory ids) external;

    function unstake(uint256[] memory ids) external;

    function getEarnedByVMM(uint256 id) external view returns (uint256);
}
