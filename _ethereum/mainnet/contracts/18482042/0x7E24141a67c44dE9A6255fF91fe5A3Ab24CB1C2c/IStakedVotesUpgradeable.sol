// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IStakedVotesUpgradeable {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Stake tokens on a given `daoContract`.
     */
    function stake(uint256 amount) external returns (bool);

    /**
     * @dev Stake tokens from signer on a given `daoContract`.
     */
    function stakeBySig(
        uint256 amount,
        uint256 fee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    /**
     * @dev Unstake tokens on a given `daoContract`.
     */
    function unstake(uint256 amount) external returns (bool);

    /**
     * @dev Unstake tokens from signer on a given `daoContract`.
     */
    function unstakeBySig(
        uint256 amount,
        uint256 fee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    /**
     * @dev Returns the amount of staked token that `account` made across all the supported contracts.
     */
    function stakeOf(address stakeholder) external view returns (uint256);

    /**
     * @dev Returns the total tokens of an address used to be staked token at the end of a past block (`blockNumber`).
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function stakeOf(address stakeholder, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had for a given `daoContract` at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total staked token available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all total staked token for a croos all the `daoContract`.
     */
    function getPastTotalStaked(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the current total staked tokens made by all users.
     * It is but NOT the sum of all the delegated votes!
     */
    function getTotalStaked() external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen for a given `daoContract`.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee` on a given `daoContract`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee` on a given `daoContract`.
     */
    function delegateBySig(
        address delegatee,
        uint256 fee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
