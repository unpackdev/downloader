// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

/**
 * @dev Interface of the Gomeme Reward Contract.
 */
interface RewardInterface {  

    /**
     * @dev Emitted when leaderboard rewards are disbursed for leaderboard ids.
     */
    event LeaderboardRegistered(string[] disbursedLeaderboardIds);

    /**
     * @dev Emitted when claim amount is transferred for the leaderboard ids.
     */
    event ClaimSuccessful(string[] claimIds);

    /**
     * @dev Emitted when the admin address is added, along with added admin address.
     */
    event AdminAdded(address adminAddress);

    /**
     * @dev Emitted when the admin address is removed, along with removed admin address.
     */
    event AdminRemoved(address adminAddress);

    /**
     * @dev Emitted when the TOKN contract is updated, along with updated TOKN contract address.
     */
    event TOKNContractUpdated(address toknContract);

    /**
     * @dev Emitted when the treasury address is updated, along with updated treasury address.
     */
    event TreasuryAddressUpdated(address treasuryAddress);

    /**
     * @dev Emitted when the TOKN is withdraw, along with to address.
     */
    event TOKNWithdrawSuccessful(address toAddress); 

    /**
     * @dev Struct containing details about the leaderboard.
     */
    struct LeaderboardDetails {
        string leaderboardId;
        bytes32 leaderboardMerkleRoot;
        bool isleaderboardActive;
    }

    /**
     * @dev Struct containing details about leaderboard winner claim details.
     */
    struct LeaderboardWinnerDetails {
        string leaderboardId;
        bytes32[] winnerMerkleProof;
        uint256 winningAmount;
    }

    /**
     * @dev Disburse leaderboard reward details.
     * @dev Only owner or admin can call this function.
     * @param leaderboardDetails Array of leaderboard rewards to be disbursed.
     */
    function disburseLeaderboardRewards(LeaderboardDetails[] calldata leaderboardDetails) external;

    /**
     * @dev Enables a user to claim multiple rewards if they are leaderboard winners.
     * @param leaderboardWinnerDetails Array of leaderboard winners details.
     */
    function claimLeaderboardRewards(LeaderboardWinnerDetails[] calldata leaderboardWinnerDetails) external;

    /**
     * @dev Adds a new admin address for the contract.
     * @dev Only owner can call this function.
     * @param addressOfAdmin The new admin address for the contract.
     */
    function addAdmin(address addressOfAdmin) external;

    /**
     * @dev Remove the admin address for the contract.
     * @dev Only owner can call this function.
     * @param addressOfAdmin The admin address to be removed from the contract.
     */
    function removeAdmin(address addressOfAdmin) external;

    /**
     * @dev Updates the TOKN contract address with the specified address.
     * @dev Only owner or admin can call this function.
     * @param toknContractAddress The new address of the TOKN contract.
     */
    function updateTOKNContract(address toknContractAddress) external;

    /**
     * @notice This function will withdraw to treasury address of the contract. 
     * @dev Withdraw the TOKN from the contract.
     * @dev Only owner can call this function.
     * @param amount Sending TOKN amount.
     */
    function TOKNWithdraw(uint256 amount) external;

    /**
     * @dev Updates the treasury address of the contract.
     * @dev Only owner can call this function.
     * @param treasuryWalletAddress Address of the treasury for handling funds.
     */
    function updateTreasuryAddress(address treasuryWalletAddress) external; 

    /**
     * @dev Retrieves the address of the TOKN contract.
     * @return toknContract The address of the TOKN contract.
     */
    function getTOKNAddress() external view returns (address);

    /**
     * @dev Pauses the contract, preventing certain functions from being executed.
     * @dev Only owner can call this function.
     */
    function pause() external;

    /**
     * @dev Unpauses the contract, allowing the execution of all functions.
     * @dev Only owner can call this function.
     */
    function unpause() external; 

}