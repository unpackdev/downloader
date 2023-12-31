// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

/**
 * @title OnChainPoll Internal Contract for OnChain Voting System
 * @author The Tech Alchemy Team
 * @notice You can use this contract for creation and ending of a poll, voters can claim their poll reward
 * @dev All function calls are currently implemented without side effects
 */

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";

import "./OnChainPollInterface.sol";
import "./POAPInterface.sol";

abstract contract OnChainPollVerifiable is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OnChainPollInterface
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
     * @dev Burnable TOKN contract address
     */
    ERC20BurnableUpgradeable internal toknContract;

    /**
     * @dev POAP NFT contract address
     */
    POAPInterface internal POAPContract;

    /**
     * @dev mapping to store onChainPoll details at the time of poll creation
     */
    mapping(uint256 => PollCreateDetails) internal createPollsDetail;

    /**
     * @dev mapping to store onChainPoll details at the time of poll end
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

        if (polls.length < 1)
            return ("Polls length is zero", 0, false);
        if (timestamp < 1)
            return ("Timestamp is zero", 0, false);  

        for (uint8 index = 0; index < polls.length; index++) {
            PollCreateDetails calldata pollCreateDetail = polls[index]; 
            if (bytes(pollCreateDetail.title).length < 1)
                return ("Poll title is empty", pollCreateDetail.pollId, false);
            if (pollCreateDetail.choices.length < 1)
                return ("Poll choices is empty", pollCreateDetail.pollId, false);
            if (timestamp > pollCreateDetail.startTime)
                return ("Invalid start time", pollCreateDetail.pollId, false);
            if (pollCreateDetail.startTime > pollCreateDetail.endTime)
                return ("Invalid end time", pollCreateDetail.pollId, false);
            if (pollCreateDetail.pollId < 1)
                return ("Invalid poll Id", pollCreateDetail.pollId, false);
            if (pollCreateDetail.creator == ZERO_ADDRESS)
                return ("Poll creator address is zero",pollCreateDetail.pollId,false);
            if (createPollsDetail[pollCreateDetail.pollId].startTime > 0)
                return ("Poll id already exists", pollCreateDetail.pollId, false);
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

        if (polls.length < 1)
            return ("Polls length is zero", 0, false);
        if (timestamp < 1)
            return ("Timestamp is zero", 0, false);  
            
        for (uint8 index = 0; index < polls.length; index++) {
            PollEndDetails calldata pollEndDetail = polls[index]; 
            if (createPollsDetail[pollEndDetail.pollId].startTime < 1)
                return ("Poll is not created", pollEndDetail.pollId, false);
            if (endPollsDetail[pollEndDetail.pollId].isPollEnded)
                return ("Poll is already ended", pollEndDetail.pollId, false);
            if (timestamp < (createPollsDetail[pollEndDetail.pollId].endTime))
                return ("The provided timestamp is earlier than the end time",pollEndDetail.pollId,false);
            if (bytes(pollEndDetail.pollMetadata).length < 1)
                return ("Empty poll meta data", pollEndDetail.pollId, false);
            if (bytes(pollEndDetail.winningChoice).length < 1)
                return ("Empty winning choice", pollEndDetail.pollId, false);
            if (pollEndDetail.fee < 1)
                return ("Poll fee is zero", pollEndDetail.pollId, false);
            if(!((pollEndDetail.winnersMerkle != bytes32(0) && pollEndDetail.votersMerkle != bytes32(0)) || (pollEndDetail.winnersMerkle == bytes32(0) && pollEndDetail.votersMerkle == bytes32(0))))
               return ("Invalid merkle root", pollEndDetail.pollId, false);
            if (!pollEndDetail.isPollEnded)
                return ("Poll ended should be true", pollEndDetail.pollId, false);
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
        returns (string memory errorMessage, uint256 pollId, bool isClaimRewardValid)
    { 
        if (pollsReward.length < 1)
            return ("Poll reward length is zero", 0, false); 

        for (uint8 index = 0; index < pollsReward.length; index++) {
           PollClaimReward calldata pollClaimRewardDetail = pollsReward[index];
            if (pollClaimRewardDetail.pollId < 1)
                return ("Poll id is zero", pollClaimRewardDetail.pollId, false);
            if (isPollRewardClaimed[pollClaimRewardDetail.pollId][msg.sender])
                return ("Reward is already claimed for this poll id",pollClaimRewardDetail.pollId,false);
            if (!endPollsDetail[pollClaimRewardDetail.pollId].isPollEnded)
                return ("Poll is not ended", pollClaimRewardDetail.pollId, false); 
            bytes32 encodedLeaf = keccak256(
                abi.encode(msg.sender, pollClaimRewardDetail.amount)
            ); 
            bool isValid = MerkleProofUpgradeable.verify(
                pollClaimRewardDetail.merkleProof,
                endPollsDetail[pollClaimRewardDetail.pollId].winnersMerkle,
                encodedLeaf
            ); 
            if (!isValid) {
                return ("Invalid merkle proof",pollClaimRewardDetail.pollId,false);  
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
        returns (string memory errorMessage, uint256 pollId, bool isClaimNFTValid)
    { 
        if (pollsClaimNFT.length < 1)
            return ("Poll length is zero", 0, false); 
        for (uint8 index = 0; index < pollsClaimNFT.length; index++) {
            PollClaimNFT calldata pollClaimAllNFTDetail = pollsClaimNFT[index];
            if (pollClaimAllNFTDetail.pollId < 1)
                return ("Poll id is zero", pollClaimAllNFTDetail.pollId, false); 
            if (isVoterNFTClaimed[pollClaimAllNFTDetail.pollId][msg.sender])
                return ("NFT is already claimed for this poll id", pollClaimAllNFTDetail.pollId, false);
            if (!endPollsDetail[pollClaimAllNFTDetail.pollId].isPollEnded)
                return ("Poll is not ended", pollClaimAllNFTDetail.pollId, false);
            bytes32 encodedLeaf = keccak256(abi.encode(msg.sender));
            bool isValid = MerkleProofUpgradeable.verify(
                pollClaimAllNFTDetail.merkleProof,
                endPollsDetail[pollClaimAllNFTDetail.pollId].votersMerkle,
                encodedLeaf
            ); 
            if (!isValid) {
                return ("Invalid merkle proof", pollClaimAllNFTDetail.pollId,false);  
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
            EndCompetitionDetails calldata endCompetitionDetail = endCompetitionDetails[index];
            for (uint256 winnerIndex = 0; winnerIndex < endCompetitionDetail.toAddress.length; winnerIndex++) {
                if (endCompetitionDetail.toAddress[winnerIndex] == ZERO_ADDRESS)
                    return ("To adddress is zero address", false);
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