// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

interface IOCCStaking {
    event CreateStake(address indexed caller, uint amount);
    event RemoveStake(address indexed caller, uint amount);


    /**
     * A method for a stakeholder to create a stake.
     *
     * @param stake - The size of the stake to be created.
     */
    function createStake(uint stake) external;

    /**
     * A method for a stakeholder to create a stake for someone else.
     *
     * @param stake - The size of the stake to be created.
     * @param to - The address the new stake belongs to.
     */
    function createStakeFor(uint stake, address to) external;

    /**
     * A method for a stakeholder to remove a stake.
     *
     * @param stake - The size of the stake to be removed.
     */
    function removeStake(uint stake) external;

    /**
     * A method which returns how much tokens stakeholder staked.
     *
     * @param user - address of stakeholder.
     */
    function getStake(address user) external view returns (uint);



     /**
     * A method to change unstaking fee ratio.
     * @notice Only callable by owner.
     *
     * @param newUnstakingFeeRatio - new unstaking fee ratio.
     */
    function changeUnstakingFeeRatio(uint newUnstakingFeeRatio) external;

    /**
     * A method to change OCC Distributor smart contract.
     * @notice Only callable by owner.
     *
     * @param newOCCDistributor - address of new OCC Distributor smart contract.
     */
    function changeOCCDistributor(address newOCCDistributor) external;
}
