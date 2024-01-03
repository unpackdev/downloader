// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;
import "./IStakingPool.sol";

interface IStakingNFTDescriptor {

    function getActiveDeposits(
        uint tokenId,
        IStakingPool stakingPool
    ) external view returns (
        string memory depositInfo,
        uint totalStake,
        uint pendingRewards
    );

}
