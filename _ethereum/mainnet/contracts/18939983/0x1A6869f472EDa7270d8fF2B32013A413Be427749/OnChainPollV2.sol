// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

/**
 * @title OnChainPoll Contract for OnChain Voting System
 * @author The Tech Alchemy Team
 * @notice You can use this contract for creation and ending of a poll, voters can claim their poll reward
 * @dev All function calls are currently implemented without side effects
 */

import "./OnChainPollV1.sol";

contract OnChainPollV2 is OnChainPollV1 {

    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint32;

    /** 
     * @dev Struct containing details about a poll at creation.
     */
    struct PollCreateDetailsV2 {
        string title;
        string[] choices;
        uint256 pollId;
        uint256 startTime;
        uint256 endTime;
        address creator;
        ERC20Upgradeable feeToken;
    }

    /**
     * @dev Struct containing poll details.
     */
    struct PollDetailsV2 {
        PollCreateDetailsV2 createPollDetails;
        PollEndDetails endPollDetails;
    }

    /**
     * @dev mapping to store onChainPoll details at the time of poll creation
     */
    mapping(uint256 => PollCreateDetailsV2) internal createPollsDetailV2;

    /**
     * @dev Verify the poll creation data is valid or not.
     * @param polls An array of data which needs to be verified.
     * @param timestamp A timestamp from the server.
     */
    function verifyCreatePollDetailsV2(
        PollCreateDetailsV2[] calldata polls,
        uint256 timestamp
    )
        public
        view
        returns (string memory errorMessage, uint256 pollId, bool isPollValid)
    {
        uint256 pollsLength = polls.length;
        if (pollsLength < 1 || timestamp < 1) {
            return ("Invalid input parameters", 0, false);
        }

        for (uint8 index = 0; index < pollsLength; index++) {
            PollCreateDetailsV2 calldata pollCreateDetail = polls[index];
            uint256 pollCreateId = pollCreateDetail.pollId;
            if (bytes(pollCreateDetail.title).length < 1)
                return ("Poll title is empty", pollCreateId, false);
            if (pollCreateDetail.choices.length < 1)
                return ("Poll choices is empty", pollCreateId, false);
            if (timestamp > pollCreateDetail.startTime || pollCreateDetail.startTime > pollCreateDetail.endTime)
                return ("Invalid start time and end time", pollCreateId, false);
            if (pollCreateId < 1)
                return ("Invalid poll Id", pollCreateId, false);
            if (pollCreateDetail.creator == ZERO_ADDRESS)
                return ("Poll creator address is zero", pollCreateId, false);
            if (pollCreateDetail.feeToken == ERC20Upgradeable(ZERO_ADDRESS))
                return ("Poll fee token is zero", pollCreateId, false);
            if (createPollsDetailV2[pollCreateId].startTime > 0)
                return ("Poll id already exists", pollCreateId, false);
        }
        
        return ("Valid create poll details", polls[0].pollId, true);
    }

    /**
     * @dev Verify the poll end data is valid or not.
     * @param polls An array of data which needs to be verified.
     * @param timestamp A timestamp from the server.
     */
    function verifyEndPollDetailsV2(
        PollEndDetails[] calldata polls,
        uint256 timestamp
    )
        public
        view
        returns (string memory errorMessage, uint256 pollId, bool isPollValid)
    {
        uint256 pollsLength = polls.length;
        if (pollsLength < 1 || timestamp < 1) {
            return ("Invalid input parameters", 0, false);
        }
            
        for (uint8 index = 0; index < pollsLength; index++) {
            PollEndDetails calldata pollEndDetail = polls[index];
            uint256 pollEndId = pollEndDetail.pollId;
            if (createPollsDetailV2[pollEndId].startTime < 1 || endPollsDetail[pollEndId].isPollEnded)
                return ("Poll is not created or already ended", pollEndId, false);
            if (timestamp < (createPollsDetailV2[pollEndId].endTime))
                return ("Poll not ended", pollEndId, false);
            if (bytes(pollEndDetail.pollMetadata).length < 1)
                return ("Empty poll meta data", pollEndId, false);
            if (bytes(pollEndDetail.winningChoice).length < 1)
                return ("Empty winning choice", pollEndId, false);
            if (pollEndDetail.fee < 1)
                return ("Poll fee is zero", pollEndId, false);
            if(!((pollEndDetail.winnersMerkle != ZERO_BYTES_32 && pollEndDetail.votersMerkle != ZERO_BYTES_32) || (pollEndDetail.winnersMerkle == ZERO_BYTES_32 && pollEndDetail.votersMerkle == ZERO_BYTES_32)))
               return ("Invalid merkle root", pollEndId, false);
            if (!pollEndDetail.isPollEnded)
                return ("Poll ended should be true", pollEndId, false);
        }
        
        return ("Valid end poll details", polls[0].pollId, true);
    }

    /**
     * @notice This function utilizes the verifyCreatePollDetails function 
     * to authenticate the details of the polls.
     * @dev Creates a new poll with the specified parameters.
     * @dev Only owner or admin can call this function.
     * @param polls An array of data for the new polls to be created.
     * @param timestamp A timestamp from the server.
     */
    function createPollsV2(
        PollCreateDetailsV2[] calldata polls,
        uint256 timestamp
    ) external onlyAdminOrOwner whenNotPaused nonReentrant {
        (, , bool isPollValid) = verifyCreatePollDetailsV2(polls, timestamp);
        require(
            isPollValid,
            "OnChainPoll: Invalid polls detail"
        );
        uint256 pollsLength = polls.length;
        uint256[] memory successPollIds = new uint256[](pollsLength);

        for (uint8 index = 0; index < pollsLength; index++) {
            uint256 pollId = polls[index].pollId; 
            createPollsDetailV2[pollId] = polls[index]; 
            successPollIds[index] = pollId; 
        }
        emit PollsCreated(successPollIds);
    }

    /**
     * @dev This function concludes the specified polls by providing the necessary 
     * information and utilizes the verifyEndPollDetails function.
     * @dev Only owner or admin can call this function.
     * @param polls An array of polls to be concluded.
     * @param timestamp A timestamp from the server.
     */
    function endPollsV2(
        PollEndDetails[] calldata polls,
        uint256 timestamp
    ) external onlyAdminOrOwner whenNotPaused nonReentrant { 
        (, , bool isPollValid) = verifyEndPollDetailsV2(polls, timestamp);
        require(
            isPollValid,
            "OnChainPoll: Invalid polls detail"
        );
        uint256 pollsLength = polls.length;
        uint256[] memory successPollIds = new uint256[](pollsLength); 
        for (uint8 index = 0; index < pollsLength; index++) {
            PollEndDetails calldata pollDetail = polls[index];
            endPollsV2Internal(pollDetail);
            successPollIds[index] = pollDetail.pollId;
        }
        
        emit PollsEnded(successPollIds);
    }

    /**
     * @dev This function concludes the specified polls and transfer the relevant fees.
     * @param pollDetail Poll end details from the poll end function.
     */
    function endPollsV2Internal(PollEndDetails calldata pollDetail) internal {
        uint256 pollId = pollDetail.pollId;
        uint256 fee = pollDetail.fee;
        ERC20Upgradeable feeToken = ERC20Upgradeable(createPollsDetailV2[pollId].feeToken);
        uint256 platformFee = calculatePlatformFee(fee, pollDetail.winnersMerkle);
        uint256 burnFee = calculateBurnFee(fee);

        if (feeToken == ERC20Upgradeable(toknContract)) {
            toknContract.burn(burnFee);
        } else {
            platformFee = platformFee.add(burnFee);
        }
        require(feeToken.transfer(treasuryAddress, platformFee), "OnChainPoll: Transfer token error");
        endPollsDetail[pollId] = pollDetail;
    }

    /**
     * @dev This function calculates the burn fee for the ending poll.
     * @param fee Poll creation fee from the poll details.
     */
    function calculateBurnFee(uint256 fee) internal view returns (uint256) {
        return (fee.mul(burnPercent)).div(MAX_PERCENTAGE);
    }

    /**
     * @dev This function calculates the platform fee for the ending poll.
     * @param fee Poll creation fee from the poll details.
     * @param winnersMerkle Winners merkle root from the poll details.
     */
    function calculatePlatformFee(uint256 fee, bytes32 winnersMerkle) internal view returns (uint256 platformFee) {
        if (winnersMerkle != ZERO_BYTES_32) {
            platformFee = fee.mul(platformPercent);
        } else {
            platformFee = fee.mul(MAX_PERCENTAGE.sub(burnPercent));
        }
        platformFee = platformFee.div(MAX_PERCENTAGE);
    }

    /**
     * @notice This function utilizes the verifyClaimAllRewardDetails function
     * to authenticate the reward details.
     * @dev Enables a user to claim multiple rewards if the user's choice is the winning one.
     * @param pollsReward An array of eligible poll rewards.
     */
    function claimAllRewardsV2(
        PollClaimReward[] calldata pollsReward
    ) public whenNotPaused nonReentrant {
        (, , bool isClaimRewardValid) = verifyClaimAllRewardDetails(pollsReward);
        require(
            isClaimRewardValid,
            "OnChainPoll: Invalid reward claims detail"
        );
        uint256 pollsLength = pollsReward.length;
        uint256[] memory successPollIds = new uint256[](pollsLength); 
        for (uint8 index = 0; index < pollsLength; index++) {
            PollClaimReward calldata pollRewardDetail = pollsReward[index];
            uint256 rewardPollId = pollRewardDetail.pollId;
            uint256 transferAmount = pollRewardDetail.amount;
            if (createPollsDetailV2[rewardPollId].pollId != 0 && createPollsDetailV2[rewardPollId].creator != ZERO_ADDRESS && address(createPollsDetailV2[rewardPollId].feeToken) != ZERO_ADDRESS) {
                isPollRewardClaimed[rewardPollId][_msgSender()] = true;
                successPollIds[index] = rewardPollId;
                ERC20Upgradeable feeTokenContract = createPollsDetailV2[rewardPollId].feeToken;
                uint256 balanceOfContract = feeTokenContract.balanceOf(address(this));
                require(
                    balanceOfContract > transferAmount,
                    "OnChainPoll: Contract does not have sufficient balance"
                );
                require(
                    feeTokenContract.transfer(_msgSender(), transferAmount),
                    "OnChainPoll: Transfer token error"
                );
            }
            else {
                PollClaimReward[] memory singlePollReward = new PollClaimReward[](1);
                singlePollReward[0] = pollRewardDetail;
                claimAllRewards(singlePollReward);
                successPollIds[index] = rewardPollId;
            }
        }
        emit ClaimTransferSuccessful(successPollIds);
    }

    /**
     * @notice This function utilizes the verifyClaimAllRewardDetails and verifyClaimAllNFTDetails function
     * to authenticate the user claims
     * @dev Enables a user to claim multiple rewards and claim NFTs if the user's choice is the winning one.
     * @param pollsReward An array of eligible poll rewards.
     * @param pollsClaimNFT An array of poll details for claiming its NFTs.
     */
    function claimAllRewardsAndNFTsV2(
        PollClaimReward[] calldata pollsReward,
        PollClaimNFT[] calldata pollsClaimNFT
    ) external whenNotPaused {
        claimAllRewardsV2(pollsReward);
        claimAllNFTs(pollsClaimNFT);
    }

    /**
     * @dev Retrieves the poll detail.
     * @param id Poll id to fetch the poll details.
     * @return PollDetail The poll detail.
     */
    function getPollDetailV2(
        uint256 id
    ) external view returns (PollDetailsV2 memory) {
        return
            PollDetailsV2({
                createPollDetails: createPollsDetailV2[id],
                endPollDetails: endPollsDetail[id]
            });
    }
}