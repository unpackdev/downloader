// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

/**
 * @dev Interface of the OnChainPoll Contract for OnChain Voting System.
 */
interface OnChainPollInterface {  
    /**
     * @dev Emitted when polls are created, along with created poll ids.
     */
    event PollsCreated(uint256[] pollIds);

    /**
     * @dev Emitted when polls are ended, along with ended poll ids.
     */
    event PollsEnded(uint256[] pollIds);

    /**
     * @dev Emitted when claim is transfered for the poll ids.
     */
    event ClaimTransferSuccessful(uint256[] pollIds);

    /**
     * @dev Emitted when NFT is transfered for the poll ids
     */
    event NFTTransferSuccessful(uint256[] pollIds, uint256[] tokenIds);

    /**
     * @dev Emitted when the poll fee is updated, along with updated poll fee.
     */
    event PollFeeUpdated(uint256 fee);

    /**
     * @dev Emitted when the burn fee is updated, along with updated burn fee.
     */
    event BurnFeeUpdated(uint256 fee);

    /**
     * @dev Emitted when the tranfer percent is updated, along with updated percent for transfer.
     */
    event TranferPercentUpdated(uint256 percentForPlatform);

    /**
     * @dev Emitted when the TOKN contract is updated, along with updated TOKN contract address.
     */
    event TOKNContractUpdated(address toknContract);

    /**
     * @dev Emitted when the POAP contract is updated, along with updated POAP contract address.
     */
    event POAPContractUpdated(address POAPContract);

    /**
     * @dev Emitted when the treasury address is updated, along with updated treasury address.
     */
    event TreasuryAddressUpdated(address treasuryWalletAddress);

    /**
     * @dev Emitted when the admin address is added, along with added admin address.
     */
    event AdminAdded(address adminAddress);

    /**
     * @dev Emitted when the admin address is removed, along with removed admin address.
     */
    event AdminRemoved(address adminAddress);

    /**
     * @dev Emitted when the competition amount is transferred successfully, along with to addresses.
     */
    event CompetitionsEnded(uint256[] competitionIds);

    /**
     * @dev Emitted when competition reward is transfered for the competition ids.
     */
    event ClaimCompetitionRewardSuccessful(uint256[] competitionIds);

    /**
     * @dev Emitted when the TOKN is withdraw, along with to address.
     */
    event TOKNWithdrawSuccessful(address toAddress); 

    /**
     * @dev Struct containing details about a poll at creation.
     */
    struct PollCreateDetails {
        string title;
        string[] choices;
        uint256 pollId;
        uint256 startTime;
        uint256 endTime;
        address creator;
    }

    /**
     * @dev Struct containing details about a poll when it is ended.
     */
    struct PollEndDetails {
        string winningChoice;
        string pollMetadata;
        uint256 pollId;
        uint256 fee;
        bytes32 winnersMerkle;
        bytes32 votersMerkle;
        bool isPollEnded;
    }

    /**
     * @dev Struct containing details about claim for a poll reward.
     */
    struct PollClaimReward {
        uint256 amount;
        uint256 pollId;
        bytes32[] merkleProof;
    }

    /**
     * @dev Struct containing details about claim for a poll NFT.
     */
    struct PollClaimNFT {
        uint256 pollId;
        bytes32[] merkleProof;
    }

    /**
     * @dev Struct containing competition winning details.
     */
    struct EndCompetitionDetails {
        uint256 amount;
        uint256 competitionId;
        address[] toAddress;
    }

    /**
     * @dev Struct containing poll details.
     */
    struct PollDetails {
        PollCreateDetails createPollDetails;
        PollEndDetails endPollDetails;
    }

    /**
     * @dev Concludes the specified polls by providing the necessary information.
     * @dev Only owner or admin can call this function.
     * @param polls An array of polls to be concluded.
     * @param timestamp A timestamp from the server.
     */
    function endPolls(
        PollEndDetails[] calldata polls,
        uint256 timestamp
    ) external;

    /**
     * @dev Enables a user to claim multiple rewards if the user's choice is the winning one.
     * @param pollsReward An array of eligible poll rewards.
     */
    function claimAllRewards(PollClaimReward[] calldata pollsReward) external;

    /**
     * @dev Allows a user to claim multiple NFTs.
     * @param pollsClaimNFT An array of poll details for claiming its NFTs.
     */
    function claimAllNFTs(PollClaimNFT[] calldata pollsClaimNFT) external;

    /**
     * @dev Enables a user to claim multiple rewards and claim NFTs if the user's choice is the winning one.
     * @param pollsReward An array of eligible poll rewards.
     * @param pollsClaimNFT An array of poll details for claiming its NFTs.
     */
    function claimAllRewardsAndNFTs(
        PollClaimReward[] calldata pollsReward,
        PollClaimNFT[] calldata pollsClaimNFT
    ) external;

    /**
     * @notice This function utilizes the verifyEndCompetition 
     * function to authenticate the information of the competition winner.
     * @dev Only owner or admin can call this function.
     * @param endCompetitionDetails Contains end competition details.
     */
    function endCompetition(
        EndCompetitionDetails[] calldata endCompetitionDetails
    ) external;

    /**  
     * @dev Allows a user to claim multiple competition reward.
     * @param competitonIds An array of competition ids.
     */
    function claimCompetitionReward(uint256[] memory competitonIds) external;

    /**
     * @notice This function will withdraw to treasury address of the contract. 
     * @dev Withdraw the TOKN from the contract.
     * @dev Only owner can call this function.
     * @param amount Sending TOKN amount.
     */
    function TOKNWithdraw(uint256 amount) external;

    /**
     * @dev Updates the poll fee with the specified amount.
     * @dev Only owner or admin can call this function.
     * @param fee The new amount of fee for creation of a poll.
     */
    function updatePollFee(uint256 fee) external;

    /**
     * @dev Updates the TOKN contract address with the specified address.
     * @dev Only owner or admin can call this function.
     * @param toknContractAddress The new address of the TOKN contract.
     */
    function updateTOKNContract(address toknContractAddress) external;

    /**
     * @dev Updates the POAP contract address with the specified address.
     * @dev Only owner or admin can call this function.
     * @param POAPContractAddress The new address of the POAP contract.
     */
    function updatePOAPContract(address POAPContractAddress) external;

    /**
     * @dev Updates the burn percentage for the contract.
     * @dev Only owner or admin can call this function.
     * @param percentForBurn The new burn percent for the token.
     */
    function updateBurnPercent(uint16 percentForBurn) external;

    /**
     * @dev Updates the treasury address of the contract.
     * @dev Only owner can call this function.
     * @param treasuryWalletAddress Address of the treasury for handling funds.
     */
    function updateTreasuryAddress(address treasuryWalletAddress) external;

    /**
     * @dev Updates the transfer percent.
     * @dev Only owner can call this function.
     * @param percentForPlatform Percent of the token tranfer to treasury.
     */
    function updateTransferPercent(uint256 percentForPlatform) external;

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
     * @dev Retrieves the poll detail.
     * @param id Poll id to fetch the poll details.
     * @return PollDetail The poll detail.
     */
    function getPollDetail(
        uint256 id
    ) external view returns (PollDetails memory);

    /**
     * @dev Retrieves the poll fee.
     * @return pollFee The poll fee.
     */
    function getPollFee() external view returns (uint256);

    /**
     * @dev Retrieves the burn percent of the TOKN.
     * @return burnPercent The burn percent.
     */
    function getBurnPercent() external view returns (uint256);

    /**
     * @dev Retrieves the platform percent.
     * @return platformPercent The plaform percent.
     */
    function getPlatformPercent() external view returns (uint256);

    /**
     * @dev Retrieves the address of the treasury.
     * @return treasuryAddress The address of the treasury.
     */
    function getTreasuryAddress() external view returns (address);

    /**
     * @dev Retrieves the address of the TOKN contract.
     * @return toknContract The address of the TOKN contract.
     */
    function getTOKNAddress() external view returns (address);

    /**
     * @dev Retrieves the address of the POAP contract.
     * @return POAPContract The address of the POAP contract.
     */
    function getPOAPAddress() external view returns (address);

    /**
     * @dev Checks if the given address is admin.
     * @return isAdmin admin or not.
     */
    function verifyAdminAddress(
        address adminAddress
    ) external view returns (bool);
}