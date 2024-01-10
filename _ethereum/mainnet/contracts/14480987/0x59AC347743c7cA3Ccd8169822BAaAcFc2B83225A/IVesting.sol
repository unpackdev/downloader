//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IVesting
 * @author gotbit
 */

interface IVesting {
    event StartVesting(uint256 indexed timestamp, address indexed user);
    event SetRoot(uint256 indexed timestamp, address indexed user, bytes32 root);
    event SetQuarters(
        uint256 indexed timestamp,
        address indexed user,
        string round,
        uint256 newQuarters
    );
    event SetRounds(uint256 indexed timestamp, address indexed user, string[] rounds);
    event Claim(uint256 indexed timestamp, address indexed user, uint256 amount);
    event Start(uint256 indexed timestamp, address indexed user);

    /// @dev starts vesting
    function start() external;

    /// @dev sets root for round
    /// @param root Merke tree root
    function setRoot(bytes32 root) external;

    /// @dev sets quarters for round
    /// @param round name of round
    /// @param newQuarters new amount of quarters for round
    function setQuarters(string memory round, uint256 newQuarters) external;

    /// @dev sets parameters for round
    /// @param rounds names of rounds
    function setRounds(string[] memory rounds) external;

    /// @dev claims the reward
    /// @param allocations of tokens
    /// @param proof Merkle tree proof
    function claim(uint256[] memory allocations, bytes32[] memory proof) external;

    /// @dev total reward for user
    /// @param user address of user
    /// @param allocations of tokens
    /// @param proof Merkle tree proof
    /// @return unclaimed amount of tokens to claim
    function unclaimed(
        address user,
        uint256[] memory allocations,
        bytes32[] memory proof
    ) external view returns (uint256);

    /// @dev returns reward in round with allocation
    /// @param round name of round
    /// @param allocation alloction in round
    function unclaimedPerRound(string memory round, uint256 allocation)
        external
        view
        returns (uint256);
}
