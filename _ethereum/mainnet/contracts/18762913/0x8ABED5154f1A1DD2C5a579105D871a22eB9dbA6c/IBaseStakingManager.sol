// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @title IBaseStakingManager
 * @author pNetwork
 *
 * @notice
 */
interface IBaseStakingManager {
    struct Stake {
        uint256 amount;
        uint64 startDate;
        uint64 endDate;
    }

    /**
     * @dev Emitted when an user increases his stake amount.
     *
     * @param owner The owner
     * @param amount The amount to add to the current one
     */
    event AmountIncreased(address indexed owner, uint256 amount);

    /**
     * @dev Emitted when an user increases his stake duration.
     *
     * @param owner The owner
     * @param duration The staking duration to add to the current one
     */
    event DurationIncreased(address indexed owner, uint64 duration);

    /**
     * @dev Emitted when the max total supply changes
     *
     * @param maxTotalSupply The maximun total supply
     */
    event MaxTotalSupplyChanged(uint256 maxTotalSupply);

    /**
     * @dev Emitted when a staker is slashed
     *
     * @param owner The slashed user
     * @param amount The slashed amount
     * @param receiver The receiver of the released collateral
     */
    event Slashed(address indexed owner, uint256 amount, address indexed receiver);

    /**
     * @dev Emitted when an user stakes some tokens
     *
     * @param receiver The receiver
     * @param amount The staked amount
     * @param duration The staking duration
     */
    event Staked(address indexed receiver, uint256 amount, uint64 duration);

    /**
     * @dev Emitted when an user unstakes some tokens
     *
     * @param owner The Onwer
     * @param amount The unstaked amount
     */
    event Unstaked(address indexed owner, uint256 amount);

    /* @notice Changes the maximun total supply
     *
     * @param maxTotalSupply
     *
     */
    function changeMaxTotalSupply(uint256 maxTotalSupply) external;

    /*
     * @notice Slash a given staker. Burn the corresponding amount of daoPNT and send the collateral (PNT) to the receiver
     *
     * @param owner
     * @param amount
     * @param receiver
     *
     */
    function slash(address owner, uint256 amount, address receiver) external;

    /*
     * @notice Returns the owner's stake data
     *
     * @param owner
     *
     * @return the Stake struct representing the owner's stake data.
     */
    function stakeOf(address owner) external view returns (Stake memory);

    /*
     * @notice Unstake an certain amount of governance token in exchange of the same amount of staked tokens.
     *         If the specified chainId is different than the chain where the DAO is deployed, the function will trigger a pToken redeem.
     *
     * @param amount
     * @param chainId
     *
     */
    function unstake(uint256 amount, bytes4 chainId) external;

    /*
     * @notice Unstake an certain amount of governance token in exchange of the same amount of staked tokens and send them to 'receiver'.
     *         If the specified chainId is different than the chain where the
     *         DAO is deployed, the function will trigger a pToken redeem.
     *
     * @param owner
     * @param amount
     * @param chainId
     *
     */
    function unstake(address owner, uint256 amount, bytes4 chainId) external;
}
