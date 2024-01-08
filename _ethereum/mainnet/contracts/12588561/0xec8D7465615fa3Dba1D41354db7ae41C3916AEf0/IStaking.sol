// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

interface IStaking {
    /**
     * @dev stakes the `amount` of tokens for `tenure`
     *
     * Requirements:
     * `amount` should be approved by the `caller`
     * to the staking contract.
     *
     * `tenure` shoulde be mentioned in days.
     */
    function stake(uint256 amount, uint256 tenure) external returns (bool);

    /**
     * @dev claims the {amount} of tokens plus {earned} tokens
     * after the end of {tenure}
     *
     * Requirements:
     * `stakeId` of the staking instance.
     *
     * returns a boolean to show the current state of the transaction.
     */
    function claim(uint256 stakeId) external returns (bool);

    /**
     * @dev returns the amount of unclaimed tokens.
     *
     * Requirements:
     * `user` is the ethereum address of the wallet.
     * `stakeId` is the id of the staking instance.
     *
     * returns the `total amount` and the `interest earned` respectively.
     */
    function calculateClaimAmount(address user, uint256 stakeId)
        external
        view
        returns (uint256, uint256);

    /**
     * @dev transfers the governance from one account(`caller`) to another account(`_newOwner`).
     */
    function revokeOwnership(address _newOwner) external returns (bool);

    /**
     * @dev will change the ROI on the staking yield.
     *
     * `_newROI` is the ROI calculated per second considering 365 days in a year.
     * It should be in 13 precision.
     *
     * The change will be effective for new users who staked tokens after the change.
     */
    function changeROI(uint256 _newROI) external returns (bool);

    /**
     * #@dev will change the token contract (EDGEX)
     *
     * If we're migrating / moving the token contract.
     * This prevents the need for migration of the staking contract.
     */
    function updateEdgexContract(address _contractAddress)
        external
        returns (bool);
}
