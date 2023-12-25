// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./PirexCvx.sol";
import "./UnionPirexStaking.sol";

contract UnionPirexStrategy is UnionPirexStaking {
    PirexCvx public immutable pirexCvx;

    error ZeroAddress();

    constructor(
        address _pirexCvx,
        address pxCVX,
        address _distributor,
        address _vault
    ) UnionPirexStaking(pxCVX, _distributor, _vault) {
        if (_pirexCvx == address(0)) revert ZeroAddress();

        pirexCvx = PirexCvx(_pirexCvx);
    }

    /**
        @notice Redeem pxCVX rewards and transfer them to the distributor
        @param  epoch          uint256    Rewards epoch
        @param  rewardIndexes  uint256[]  Reward indexes
     */
    function redeemRewards(uint256 epoch, uint256[] calldata rewardIndexes)
        external
    {
        pirexCvx.redeemSnapshotRewards(epoch, rewardIndexes, distributor);
    }
}
