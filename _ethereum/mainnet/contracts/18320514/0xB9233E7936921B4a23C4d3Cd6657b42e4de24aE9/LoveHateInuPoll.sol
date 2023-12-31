// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/**
 * @title LoveHatePoll Internal Contract for LoveHate Voting System
 * @notice You can use this contract for creation and ending of a poll, voters can claim their poll reward
 * @dev All function calls are currently implemented without side effects
 */

import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";

/**
 * @dev Interface of the LoveHatePoll Contract for LoveHate Voting System.
 */
interface LoveHatePollInterface {
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
     * @dev Emitted when the LHINU contract is updated, along with updated LHINU contract address.
     */
    event LHINUContractUpdated(address lhinuContract);

    /**
     * @dev Emitted when the POAP contract is updated, along with updated POAP contract address.
     */
    event POAPContractUpdated(address POAPContract);

    /**
     * @dev Emitted when the treasury address is updated, along with updated treasury address.
     */
    event TreasuryAddressUpdated(address POAPContract);

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
     * @dev Emitted when the LHINU is withdraw, along with to address.
     */
    event LHINUWithdrawSuccessful(address toAddress);

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
     * @dev Creates a new poll with the specified parameters.
     * @dev Only owner or admin can call this function.
     * @param polls An array of data for the new polls to be created.
     * @param timestamp A timestamp from the server.
     */
    function createPolls(
        PollCreateDetails[] calldata polls,
        uint256 timestamp
    ) external;

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
     * @dev Withdraw the LHINU from the contract.
     * @dev Only owner can call this function.
     * @param amount Sending LHINU amount.
     */
    function LHINUWithdraw(uint256 amount) external;

    /**
     * @dev Only owner or admin can call this function.
     * @param endCompetitionDetails Contains competition winning details.
     */
    // function transferCompetitionWinnings(
    //     EndCompetitionDetails[] calldata endCompetitionDetails
    // ) external;

    /**
     * @dev Updates the poll fee with the specified amount.
     * @dev Only owner or admin can call this function.
     * @param fee The new amount of fee for creation of a poll.
     */
    function updatePollFee(uint256 fee) external;

    /**
     * @dev Updates the LHINU contract address with the specified address.
     * @dev Only owner or admin can call this function.
     * @param lhinuContractAddress The new address of the LHINU contract.
     */
    function updateLHINUContract(address lhinuContractAddress) external;

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
     * @dev Retrieves the burn percent of the LHINU.
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
     * @dev Retrieves the address of the LHINU contract.
     * @return lhinuContract The address of the LHINU contract.
     */
    function getLHINUAddress() external view returns (address);

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

interface POAPInterface {
    /**
     * @dev Emitted when NFT is minted.
     */
    event NewNFTMinted(uint256[], uint256[]);

    /**
     * @dev Emitted when the lovehatePoll contract is updated, along with updated lovehatePoll contract address.
     */
    event LoveHatePollContractUpdated(address lovehatePollContract);

    /**
     * @dev Mints a new NFT for the poll response.
     * @dev Only the lovehatePoll contract can call this function.
     * @param pollId The poll id for the NFT to be minted.
     * @param tokenUri The metadata uri for the poll data.
     * @param to The address to mint the NFT.
     */
    function mint(
        uint256 pollId,
        string calldata tokenUri,
        address to
    ) external returns (uint256);

    /**
     * @dev Updates the lovehatePoll contract's address.
     * @dev Only owner can call this function.
     * @param newLoveHatePollContract The new address of the lovehatePoll contract.
     */
    function updateLoveHatePollContract(
        address newLoveHatePollContract
    ) external;

    /**
     * @notice getTokenUri, function is used to check uri of specific token by giving pollId and tokenId.
     * @dev getTokenUri, function returns the token uri by giving pollId and tokenId.
     * @param pollId, pollId is given to the function to get corresponding uri.
     * @param tokenId, tokenId is given to the function to get corresponding uri.
     */
    function getTokenUri(
        uint256 pollId,
        uint tokenId
    ) external view returns (string memory);

    /**
     * @dev return the lovehatePoll contract's address
     */
    function getLoveHatePollContract() external returns (address);

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

abstract contract LoveHatePollVerifiable is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    LoveHatePollInterface
{
    /**
     * @dev Default static value for percent
     * @notice here 10000 represents 100%
     */
    uint32 constant MAX_PERCENTAGE = 10000;

    /**
     *  @dev Zero Address
     */
    address internal constant ZERO_ADDRESS = address(0);

    /**
     * @dev Zero Bytes
     */
    bytes32 internal constant ZERO_BYTES_32 = bytes32(0);

    /**
     * @dev Minimum poll fee for the contract
     */
    uint256 public minPollFee;

    /**
     * @dev User pay this poll fee for creating polls
     */
    uint256 internal pollFee;

    /**
     * @dev Burn percentage of the token at the time of end poll
     */
    uint256 internal burnPercent;

    /**
     * @dev Tranfer percentage of the token at the time of end poll to treasury address
     */
    uint256 internal platformPercent;

    /**
     * @dev Address of the treasury for handling funds.
     */
    address internal treasuryAddress;

    /**
     * @dev Burnable LHINU contract address
     */
    ERC20BurnableUpgradeable internal lhinuContract;

    /**
     * @dev POAP NFT contract address
     */
    POAPInterface internal POAPContract;

    /**
     * @dev mapping to store lovehatePoll details at the time of poll creation
     */
    mapping(uint256 => PollCreateDetails) internal createPollsDetail;

    /**
     * @dev mapping to store lovehatePoll details at the time of poll end
     */
    mapping(uint256 => PollEndDetails) internal endPollsDetail;

    /**
     * @dev mapping to store if the voter has claimed the POAP NFT
     */
    mapping(uint256 => mapping(address => bool)) public isVoterNFTClaimed;

    /**
     * @dev mapping to store if the winner voter claimed the poll reward
     */
    mapping(uint256 => mapping(address => bool)) public isPollRewardClaimed;

    /**
     * @dev mapping to store if the competition winner winnings
     */
    mapping(uint256 => mapping(address => uint256)) public competitionWinnings;

    /**
     * @dev mapping to store if address is an admin
     */
    mapping(address => bool) internal isAdmin;

    /**
     * @dev Verify the poll creation data is valid or not.
     * @param polls An array of data which needs to be verified.
     * @param timestamp A timestamp from the server.
     */
    function verifyCreatePollDetails(
        PollCreateDetails[] calldata polls,
        uint256 timestamp
    )
        public
        view
        returns (string memory errorMessage, uint256 pollId, bool isPollValid)
    {
        if (polls.length < 1) return ("Polls length is zero", 0, false);
        if (timestamp < 1) return ("Timestamp is zero", 0, false);

        for (uint8 index = 0; index < polls.length; index++) {
            PollCreateDetails calldata pollCreateDetail = polls[index];
            if (bytes(pollCreateDetail.title).length < 1)
                return ("Poll title is empty", pollCreateDetail.pollId, false);
            if (pollCreateDetail.choices.length < 1)
                return (
                    "Poll choices is empty",
                    pollCreateDetail.pollId,
                    false
                );
            if (timestamp > pollCreateDetail.startTime)
                return ("Invalid start time", pollCreateDetail.pollId, false);
            if (pollCreateDetail.startTime > pollCreateDetail.endTime)
                return ("Invalid end time", pollCreateDetail.pollId, false);
            if (pollCreateDetail.pollId < 1)
                return ("Invalid poll Id", pollCreateDetail.pollId, false);
            if (pollCreateDetail.creator == ZERO_ADDRESS)
                return (
                    "Poll creator address is zero",
                    pollCreateDetail.pollId,
                    false
                );
            if (createPollsDetail[pollCreateDetail.pollId].startTime > 0)
                return (
                    "Poll id already exists",
                    pollCreateDetail.pollId,
                    false
                );
        }

        return ("Valid create poll details", polls[0].pollId, true);
    }

    /**
     * @dev Verify the poll end data is valid or not.
     * @param polls An array of data which needs to be verified.
     * @param timestamp A timestamp from the server.
     */
    function verifyEndPollDetails(
        PollEndDetails[] calldata polls,
        uint256 timestamp
    )
        public
        view
        returns (string memory errorMessage, uint256 pollId, bool isPollValid)
    {
        if (polls.length < 1) return ("Polls length is zero", 0, false);
        if (timestamp < 1) return ("Timestamp is zero", 0, false);

        for (uint8 index = 0; index < polls.length; index++) {
            PollEndDetails calldata pollEndDetail = polls[index];
            if (createPollsDetail[pollEndDetail.pollId].startTime < 1)
                return ("Poll is not created", pollEndDetail.pollId, false);
            if (endPollsDetail[pollEndDetail.pollId].isPollEnded)
                return ("Poll is already ended", pollEndDetail.pollId, false);
            if (timestamp < (createPollsDetail[pollEndDetail.pollId].endTime))
                return (
                    "The provided timestamp is earlier than the end time",
                    pollEndDetail.pollId,
                    false
                );
            if (bytes(pollEndDetail.pollMetadata).length < 1)
                return ("Empty poll meta data", pollEndDetail.pollId, false);
            if (bytes(pollEndDetail.winningChoice).length < 1)
                return ("Empty winning choice", pollEndDetail.pollId, false);
            if (pollEndDetail.fee < 1)
                return ("Fee for poll is zero", pollEndDetail.pollId, false);
            if (
                !((pollEndDetail.winnersMerkle != bytes32(0) &&
                    pollEndDetail.votersMerkle != bytes32(0)) ||
                    (pollEndDetail.winnersMerkle == bytes32(0) &&
                        pollEndDetail.votersMerkle == bytes32(0)))
            ) return ("invalid merkle", pollEndDetail.pollId, false);
            if (!pollEndDetail.isPollEnded)
                return (
                    "Poll ended should be true",
                    pollEndDetail.pollId,
                    false
                );
        }

        return ("Valid end poll details", polls[0].pollId, true);
    }

    /**
     * @dev Verify the claim reward data is valid or not.
     * @param pollsReward The data which needs to be verified.
     */
    function verifyClaimAllRewardDetails(
        PollClaimReward[] calldata pollsReward
    )
        public
        view
        returns (
            string memory errorMessage,
            uint256 pollId,
            bool isClaimRewardValid
        )
    {
        if (pollsReward.length < 1)
            return ("Poll reward length is zero", 0, false);

        for (uint8 index = 0; index < pollsReward.length; index++) {
            PollClaimReward calldata pollClaimRewardDetail = pollsReward[index];
            if (pollClaimRewardDetail.pollId < 1)
                return ("Poll id is zero", pollClaimRewardDetail.pollId, false);
            if (isPollRewardClaimed[pollClaimRewardDetail.pollId][msg.sender])
                return (
                    "Reward is already claimed for this poll id",
                    pollClaimRewardDetail.pollId,
                    false
                );
            if (!endPollsDetail[pollClaimRewardDetail.pollId].isPollEnded)
                return (
                    "Poll is not ended",
                    pollClaimRewardDetail.pollId,
                    false
                );
            bytes32 encodedLeaf = keccak256(
                abi.encode(msg.sender, pollClaimRewardDetail.amount)
            );
            bool isValid = MerkleProofUpgradeable.verify(
                pollClaimRewardDetail.merkleProof,
                endPollsDetail[pollClaimRewardDetail.pollId].winnersMerkle,
                encodedLeaf
            );
            if (!isValid) {
                return (
                    "Invalid merkle proof",
                    pollClaimRewardDetail.pollId,
                    false
                );
            }
        }
        return ("Valid reward claim details", pollsReward[0].pollId, true);
    }

    /**
     * @dev Verify the claim NFT data is valid or not.
     * @param pollsClaimNFT The data which needs to be verified.
     */
    function verifyClaimAllNFTDetails(
        PollClaimNFT[] calldata pollsClaimNFT
    )
        public
        view
        returns (
            string memory errorMessage,
            uint256 pollId,
            bool isClaimNFTValid
        )
    {
        if (pollsClaimNFT.length < 1) return ("Poll length is zero", 0, false);
        for (uint8 index = 0; index < pollsClaimNFT.length; index++) {
            PollClaimNFT calldata pollClaimAllNFTDetail = pollsClaimNFT[index];
            if (pollClaimAllNFTDetail.pollId < 1)
                return ("Poll id is zero", pollClaimAllNFTDetail.pollId, false);
            if (isVoterNFTClaimed[pollClaimAllNFTDetail.pollId][msg.sender])
                return (
                    "NFT is already claimed for this poll id",
                    pollClaimAllNFTDetail.pollId,
                    false
                );
            if (!endPollsDetail[pollClaimAllNFTDetail.pollId].isPollEnded)
                return (
                    "Poll is not ended",
                    pollClaimAllNFTDetail.pollId,
                    false
                );
            bytes32 encodedLeaf = keccak256(abi.encode(msg.sender));
            bool isValid = MerkleProofUpgradeable.verify(
                pollClaimAllNFTDetail.merkleProof,
                endPollsDetail[pollClaimAllNFTDetail.pollId].votersMerkle,
                encodedLeaf
            );
            if (!isValid) {
                return (
                    "Invalid merkle proof",
                    pollClaimAllNFTDetail.pollId,
                    false
                );
            }
        }
        return ("Valid NFT claim details", pollsClaimNFT[0].pollId, true);
    }

    /**
     * @dev Verify the transfer competition winning is valid or not.
     * @param endCompetitionDetails The data which needs to be verified.
     * @param balanceOfContract The balance of the smart contract.
     */
    function verifyEndCompetition(
        EndCompetitionDetails[] calldata endCompetitionDetails,
        uint256 balanceOfContract
    )
        public
        pure
        returns (string memory errorMessage, bool isCompetitionValid)
    {
        if (endCompetitionDetails.length < 1)
            return ("Competition details length is zero", false);

        for (uint8 index = 0; index < endCompetitionDetails.length; index++) {
            EndCompetitionDetails
                calldata endCompetitionDetail = endCompetitionDetails[index];
            for (
                uint256 winnerIndex = 0;
                winnerIndex < endCompetitionDetail.toAddress.length;
                winnerIndex++
            ) {
                if (endCompetitionDetail.toAddress[winnerIndex] == ZERO_ADDRESS)
                    return ("to address is zero address", false);
            }
            if (endCompetitionDetail.amount < 1)
                return ("Transfer amount is zero", false);
            if (endCompetitionDetail.amount > balanceOfContract)
                return ("Contract does not have sufficient balance", false);
            balanceOfContract -= endCompetitionDetail.amount;
        }
        return ("Valid transfer competition winning details", true);
    }

    /**
     * @dev Pauses the contract, preventing certain functions from being executed.
     * @dev Only owner can call this function.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing the execution of all functions.
     * @dev Only owner can call this function.
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}

contract LoveHatePoll is LoveHatePollVerifiable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev The initialize function sets the owner of the contract at the time of deployment
     * @param minFee - Minimum fee for the contract.
     * @param percentForBurn - Percent for burning the token.
     * @param percentForPlatform - Percent for transfer the token to treasury wallet address.
     * @param feeForPoll - Fee for the poll creation, User pays this fee at the time of poll creation.
     * @param lhinuContractAddress - Address of the LHINU contract used for paying the poll fee and reward transfer.
     * @param poapContractAddress - Address of the POAP contract used for minting the NFT to voter.
     * @param adminWalletAddress - Address of the admin of the contract.
     * @param treasuryWalletAddress - Address of the treasury for handling funds.
     */

    function initialize(
        uint256 minFee,
        uint256 percentForBurn,
        uint256 percentForPlatform,
        uint256 feeForPoll,
        address lhinuContractAddress,
        address poapContractAddress,
        address adminWalletAddress,
        address treasuryWalletAddress
    ) public initializer {
        require(minFee > 0, "LoveHatePoll: Minimum Fee is zero");
        require(
            (minFee - 1) < feeForPoll,
            "LoveHatePoll: Fee should be greater than minimum fee"
        );
        require(percentForBurn > 0, "LoveHatePoll: Burn percent is zero");
        require(
            percentForPlatform > 0,
            "LoveHatePoll: Tranfer percent is zero"
        );
        require(
            lhinuContractAddress != ZERO_ADDRESS,
            "LoveHatePoll: LHINU address is the zero address"
        );
        require(
            poapContractAddress != ZERO_ADDRESS,
            "LoveHatePoll: POAP address is the zero address"
        );
        require(
            adminWalletAddress != ZERO_ADDRESS,
            "LoveHatePoll: Admin address is the zero address"
        );
        require(
            treasuryWalletAddress != ZERO_ADDRESS,
            "LoveHatePoll: Treasury address is the zero address"
        );
        burnPercent = percentForBurn;
        platformPercent = percentForPlatform;
        pollFee = feeForPoll;
        minPollFee = minFee;
        lhinuContract = ERC20BurnableUpgradeable(lhinuContractAddress);
        POAPContract = POAPInterface(poapContractAddress);
        isAdmin[adminWalletAddress] = true;
        treasuryAddress = treasuryWalletAddress;
        __Pausable_init();
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /**
     * @notice This function utilizes the verifyCreatePollDetails function
     * to authenticate the details of the polls.
     * @dev Creates a new poll with the specified parameters.
     * @dev Only owner or admin can call this function.
     * @param polls An array of data for the new polls to be created.
     * @param timestamp A timestamp from the server.
     */
    function createPolls(
        PollCreateDetails[] calldata polls,
        uint256 timestamp
    ) external override onlyAdminOrOwner whenNotPaused nonReentrant {
        (, , bool isPollValid) = verifyCreatePollDetails(polls, timestamp);
        require(isPollValid, "LoveHatePoll: Invalid polls detail");
        uint256[] memory successPollIds = new uint256[](polls.length);

        for (uint8 index = 0; index < polls.length; index++) {
            uint256 pollId = polls[index].pollId;
            createPollsDetail[pollId] = polls[index];
            successPollIds[index] = pollId;
        }
        emit PollsCreated(successPollIds);
    }

    /**
     * @notice This function utilizes the verifyEndPollDetails function
     * to authenticate the details of the polls.
     * @dev Concludes the specified polls by providing the necessary information.
     * @dev Only owner or admin can call this function.
     * @param polls An array of polls to be concluded.
     * @param timestamp A timestamp from the server.
     */
    function endPolls(
        PollEndDetails[] calldata polls,
        uint256 timestamp
    ) external override onlyAdminOrOwner whenNotPaused nonReentrant {
        (, , bool isPollValid) = verifyEndPollDetails(polls, timestamp);
        require(isPollValid, "LoveHatePoll: Invalid polls detail");
        uint256[] memory successPollIds = new uint256[](polls.length);
        uint256 totalBurnAmount = 0;
        uint256 totalPlatformFee = 0;
        for (uint8 index = 0; index < polls.length; index++) {
            PollEndDetails calldata pollDetail = polls[index];
            endPollsDetail[pollDetail.pollId] = pollDetail;
            totalBurnAmount += (pollDetail.fee * burnPercent) / MAX_PERCENTAGE;
            if (pollDetail.winnersMerkle == ZERO_BYTES_32) {
                totalPlatformFee +=
                    (pollDetail.fee * (MAX_PERCENTAGE - burnPercent)) /
                    MAX_PERCENTAGE;
            } else {
                totalPlatformFee +=
                    (pollDetail.fee * platformPercent) /
                    MAX_PERCENTAGE;
            }
            successPollIds[index] = pollDetail.pollId;
        }
        lhinuContract.burn(totalBurnAmount);
        require(
            lhinuContract.transfer(treasuryAddress, totalPlatformFee),
            "LoveHatePoll: Transfer token error"
        );
        emit PollsEnded(successPollIds);
    }

    /**
     * @notice This function utilizes the verifyClaimAllRewardDetails function
     * to authenticate the reward details.
     * @dev Enables a user to claim multiple rewards if the user's choice is the winning one.
     * @param pollsReward An array of eligible poll rewards.
     */
    function claimAllRewards(
        PollClaimReward[] calldata pollsReward
    ) public override whenNotPaused nonReentrant {
        (, , bool isClaimRewardValid) = verifyClaimAllRewardDetails(
            pollsReward
        );
        require(
            isClaimRewardValid,
            "LoveHatePoll: Invalid reward claims detail"
        );
        uint256[] memory successPollIds = new uint256[](pollsReward.length);
        uint256 totalTransferAmount = 0;
        for (uint8 index = 0; index < pollsReward.length; index++) {
            PollClaimReward calldata pollRewardDetail = pollsReward[index];
            totalTransferAmount += pollRewardDetail.amount;
            isPollRewardClaimed[pollRewardDetail.pollId][_msgSender()] = true;
            successPollIds[index] = pollRewardDetail.pollId;
        }
        if (totalTransferAmount > 0) {
            uint256 balanceOfContract = lhinuContract.balanceOf(address(this));
            require(
                balanceOfContract > totalTransferAmount,
                "LoveHatePoll: Contract does not have sufficient balance"
            );
            require(
                lhinuContract.transfer(_msgSender(), totalTransferAmount),
                "LoveHatePoll: Transfer token error"
            );
            emit ClaimTransferSuccessful(successPollIds);
        }
    }

    /**
     * @notice This function utilizes the verifyClaimAllNFTDetails function
     * to authenticate the details of the NFT reward.
     * @dev Allows a user to claim multiple NFTs.
     * @param pollsClaimNFT An array of poll details for claiming its NFTs.
     */
    function claimAllNFTs(
        PollClaimNFT[] calldata pollsClaimNFT
    ) public override whenNotPaused nonReentrant {
        (, , bool isClaimNFTValid) = verifyClaimAllNFTDetails(pollsClaimNFT);
        require(isClaimNFTValid, "LoveHatePoll: Invalid NFT claims detail");
        uint256[] memory successPollIds = new uint256[](pollsClaimNFT.length);
        uint256[] memory successTokenIds = new uint256[](pollsClaimNFT.length);
        for (uint8 index = 0; index < pollsClaimNFT.length; index++) {
            PollClaimNFT calldata pollNFTDetail = pollsClaimNFT[index];
            isVoterNFTClaimed[pollNFTDetail.pollId][_msgSender()] = true;
            uint256 tokenId = POAPContract.mint(
                pollNFTDetail.pollId,
                endPollsDetail[pollNFTDetail.pollId].pollMetadata,
                _msgSender()
            );
            successPollIds[index] = pollNFTDetail.pollId;
            successTokenIds[index] = tokenId;
        }
        emit NFTTransferSuccessful(successPollIds, successTokenIds);
    }

    /**
     * @notice This function utilizes the verifyClaimAllRewardDetails function
     * to authenticate the reward details.
     * @notice This function utilizes the verifyClaimAllNFTDetails function
     * to authenticate the details of the NFT reward.
     * @dev Enables a user to claim multiple rewards and claim NFTs if the user's choice is the winning one.
     * @param pollsReward An array of eligible poll rewards.
     * @param pollsClaimNFT An array of poll details for claiming its NFTs.
     */
    function claimAllRewardsAndNFTs(
        PollClaimReward[] calldata pollsReward,
        PollClaimNFT[] calldata pollsClaimNFT
    ) external override whenNotPaused {
        claimAllRewards(pollsReward);
        claimAllNFTs(pollsClaimNFT);
    }

    /**
     * @notice This function utilizes the verifyEndCompetition
     * function to authenticate the information of the competition winner.
     * @dev Only owner or admin can call this function.
     * @param endCompetitionDetails Contains end competition details.
     */
    function endCompetition(
        EndCompetitionDetails[] calldata endCompetitionDetails
    ) external override onlyAdminOrOwner whenNotPaused nonReentrant {
        (, bool isValid) = verifyEndCompetition(
            endCompetitionDetails,
            lhinuContract.balanceOf(address(this))
        );
        require(isValid, "LoveHatePoll: Invalid winning competitions detail");
        uint256 totalBurnAmount = 0;
        uint256 totalPlatformFee = 0;
        uint256[] memory successCompetitionIds = new uint256[](
            endCompetitionDetails.length
        );
        for (uint8 index = 0; index < endCompetitionDetails.length; index++) {
            EndCompetitionDetails
                calldata endCompetitionDetail = endCompetitionDetails[index];
            uint256 burnAmount = (endCompetitionDetail.amount * burnPercent) /
                MAX_PERCENTAGE;
            uint256 platformFee = (endCompetitionDetail.amount *
                platformPercent) / MAX_PERCENTAGE;
            uint256 competitionWinningAmount = endCompetitionDetail.amount -
                platformFee -
                burnAmount;
            totalBurnAmount += burnAmount;
            totalPlatformFee += platformFee;
            uint256 individualWinnngAmount = competitionWinningAmount /
                endCompetitionDetail.toAddress.length;
            for (
                uint256 winnerIndex = 0;
                winnerIndex < endCompetitionDetail.toAddress.length;
                winnerIndex++
            ) {
                competitionWinnings[endCompetitionDetail.competitionId][
                    endCompetitionDetail.toAddress[winnerIndex]
                ] = individualWinnngAmount;
                competitionWinningAmount -= individualWinnngAmount;
            }

            totalPlatformFee += competitionWinningAmount;

            successCompetitionIds[index] = endCompetitionDetail.competitionId;
        }
        lhinuContract.burn(totalBurnAmount);
        require(
            lhinuContract.transfer(treasuryAddress, totalPlatformFee),
            "LoveHatePoll: Transfer token error"
        );
        emit CompetitionsEnded(successCompetitionIds);
    }

    /**
     * @dev Allows a user to claim multiple competition reward.
     * @param competitonIds An array of competition ids.
     */
    function claimCompetitionReward(
        uint256[] memory competitonIds
    ) external override whenNotPaused nonReentrant {
        require(
            competitonIds.length > 0,
            "LoveHatePoll: Competition Ids length is zero"
        );
        uint256 totalWinning = 0;
        for (uint256 index = 0; index < competitonIds.length; index++) {
            require(
                competitionWinnings[competitonIds[index]][_msgSender()] > 0,
                "LoveHatePoll: Not eligible for competition reward"
            );
            totalWinning += competitionWinnings[competitonIds[index]][
                _msgSender()
            ];
            competitionWinnings[competitonIds[index]][_msgSender()] = 0;
        }
        require(
            lhinuContract.transfer(_msgSender(), totalWinning),
            "LoveHatePoll: Transfer token error"
        );
        emit ClaimCompetitionRewardSuccessful(competitonIds);
    }

    /**
     * @notice This function will withdraw to treasury address of the contract.
     * @dev Withdraw the LHINU from the contract.
     * @dev Only owner can call this function.
     * @param amount Sending LHINU amount.
     */
    function LHINUWithdraw(
        uint256 amount
    ) external override onlyOwner whenNotPaused nonReentrant {
        uint256 balanceOfContract = lhinuContract.balanceOf(address(this));
        require(amount > 0, "LoveHatePoll: Amount is zero");
        require(
            balanceOfContract > (amount - 1),
            "LoveHatePoll: Contract does not have sufficient balance"
        );
        require(
            lhinuContract.transfer(treasuryAddress, amount),
            "LoveHatePoll: Transfer token error"
        );
        emit LHINUWithdrawSuccessful(treasuryAddress);
    }

    /**
     * @dev Updates the poll fee with the specified amount.
     * @dev Only owner or admin can call this function.
     * @param fee The new amount of fee for creation of a poll.
     */
    function updatePollFee(
        uint256 fee
    ) external override onlyAdminOrOwner whenNotPaused nonReentrant {
        require(
            (minPollFee - 1) < fee,
            "LoveHatePoll: Fee should be greater than minimum fee"
        );
        require(
            fee != pollFee,
            "LoveHatePoll: Fee shouldn't be same as previous"
        );
        pollFee = fee;
        emit PollFeeUpdated(pollFee);
    }

    /**
     * @dev Updates the LHINU contract address with the specified address.
     * @dev Only owner or admin can call this function.
     * @param lhinuContractAddress The new address of the LHINU contract.
     */
    function updateLHINUContract(
        address lhinuContractAddress
    ) external override onlyAdminOrOwner whenNotPaused nonReentrant {
        require(
            lhinuContractAddress != ZERO_ADDRESS,
            "LoveHatePoll: LHINU address is the zero address"
        );
        require(
            lhinuContractAddress != address(lhinuContract),
            "LoveHatePoll: Same as pervious address"
        );
        lhinuContract = ERC20BurnableUpgradeable(lhinuContractAddress);
        emit LHINUContractUpdated(address(lhinuContract));
    }

    /**
     * @dev Updates the POAP contract address with the specified address.
     * @dev Only owner or admin can call this function.
     * @param POAPContractAddress The new address of the POAP contract.
     */
    function updatePOAPContract(
        address POAPContractAddress
    ) external override onlyAdminOrOwner whenNotPaused nonReentrant {
        require(
            POAPContractAddress != ZERO_ADDRESS,
            "LoveHatePoll: POAP address is the zero address"
        );
        require(
            POAPContractAddress != address(POAPContract),
            "LoveHatePoll: Same as pervious address"
        );
        POAPContract = POAPInterface(POAPContractAddress);
        emit POAPContractUpdated(address(POAPContract));
    }

    /**
     * @dev Updates the burn percentage for the contract.
     * @dev Only owner or admin can call this function.
     * @param percentForBurn The new burn percent for the token.
     */
    function updateBurnPercent(
        uint16 percentForBurn
    ) external override onlyAdminOrOwner whenNotPaused nonReentrant {
        require(percentForBurn > 0, "LoveHatePoll: Burn percent is zero");
        require(
            percentForBurn != burnPercent,
            "LoveHatePoll: Burn percent shouldn't be same as previous"
        );
        burnPercent = percentForBurn;
        emit BurnFeeUpdated(burnPercent);
    }

    /**
     * @dev Updates the treasury address of the contract.
     * @dev Only owner can call this function.
     * @param treasuryWalletAddress Address of the treasury for handling funds.
     */
    function updateTreasuryAddress(
        address treasuryWalletAddress
    ) external override onlyOwner whenNotPaused nonReentrant {
        require(
            treasuryWalletAddress != ZERO_ADDRESS,
            "LoveHatePoll: Treasury address is the zero address"
        );
        require(
            treasuryWalletAddress != treasuryAddress,
            "LoveHatePoll: Same as pervious address"
        );
        treasuryAddress = treasuryWalletAddress;
        emit TreasuryAddressUpdated(treasuryAddress);
    }

    /**
     * @dev Updates the transfer percent.
     * @dev Only owner can call this function.
     * @param percentForPlatform Percent of the token tranfer to treasury.
     */
    function updateTransferPercent(
        uint256 percentForPlatform
    ) external override onlyOwner whenNotPaused nonReentrant {
        require(
            percentForPlatform > 0,
            "LoveHatePoll: Tranfer percent is zero"
        );
        require(
            platformPercent != percentForPlatform,
            "LoveHatePoll: Tranfer percent shouldn't be same as previous"
        );
        platformPercent = percentForPlatform;
        emit TranferPercentUpdated(platformPercent);
    }

    /**
     * @dev Adds a new admin address for the contract.
     * @dev Only owner can call this function.
     * @param addressOfAdmin The new admin address for the contract.
     */
    function addAdmin(
        address addressOfAdmin
    ) external override onlyOwner whenNotPaused nonReentrant {
        require(
            !isAdmin[addressOfAdmin],
            "LoveHatePoll: Address already admin"
        );
        require(
            addressOfAdmin != ZERO_ADDRESS,
            "LoveHatePoll: Admin address is the zero address"
        );
        isAdmin[addressOfAdmin] = true;
        emit AdminAdded(addressOfAdmin);
    }

    /**
     * @dev Remove the admin address for the contract.
     * @dev Only owner can call this function.
     * @param addressOfAdmin The admin address to be removed from the contract.
     */
    function removeAdmin(
        address addressOfAdmin
    ) external override onlyOwner whenNotPaused nonReentrant {
        require(isAdmin[addressOfAdmin], "LoveHatePoll: Address not admin");
        isAdmin[addressOfAdmin] = false;
        emit AdminRemoved(addressOfAdmin);
    }

    /**
     * @dev Retrieves the poll detail.
     * @param id Poll id to fetch the poll details.
     * @return PollDetail The poll detail.
     */
    function getPollDetail(
        uint256 id
    ) external view override returns (PollDetails memory) {
        return
            PollDetails({
                createPollDetails: createPollsDetail[id],
                endPollDetails: endPollsDetail[id]
            });
    }

    /**
     * @dev Retrieves the poll fee.
     * @return pollFee The poll fee.
     */
    function getPollFee() external view override returns (uint256) {
        return pollFee;
    }

    /**
     * @dev Retrieves the burn percent of the LHINU.
     * @return burnPercent The burn percent.
     */
    function getBurnPercent() external view override returns (uint256) {
        return burnPercent;
    }

    /**
     * @dev Retrieves the platform percent.
     * @return platformPercent The plaform percent.
     */
    function getPlatformPercent() external view override returns (uint256) {
        return platformPercent;
    }

    /**
     * @dev Retrieves the address of the treasury.
     * @return treasuryAddress The address of the treasury.
     */
    function getTreasuryAddress() external view override returns (address) {
        return address(treasuryAddress);
    }

    /**
     * @dev Retrieves the address of the LHINU contract.
     * @return lhinuContract The address of the LHINU contract.
     */
    function getLHINUAddress() external view override returns (address) {
        return address(lhinuContract);
    }

    /**
     * @dev Retrieves the address of the POAP contract.
     * @return POAPContract The address of the POAP contract.
     */
    function getPOAPAddress() external view override returns (address) {
        return address(POAPContract);
    }

    /**
     * @dev Checks if the given address is admin.
     * @return isAdmin admin or not.
     */
    function verifyAdminAddress(
        address adminAddress
    ) external view override returns (bool) {
        return isAdmin[adminAddress];
    }

    /**
     * @notice OnlyAdminOrOwner modifer allows only admin address or owner address to execute the funtions.
     */
    modifier onlyAdminOrOwner() {
        require(
            (_msgSender() == owner() || isAdmin[_msgSender()]),
            "LoveHatePoll: Caller not admin or owner"
        );
        _;
    }
}
