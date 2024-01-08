pragma solidity 0.8.4;

// SPDX-License-Identifier: MIT

interface ICompetition{


    /**
    PARTICIPANT WRITE METHODS
    **/

    /**
    * @dev Called by anyone ONLY VIA THE ERC20 TOKEN CONTRACT to increase their stake.
    * @param staker The address of the staker that wants to increase their stake.
    * @param amountToken The amount to add to their stake.
    * @return success True if the operation completed successfully.
    **/
    function increaseStake(address staker, uint256 amountToken) external returns (bool success);

    /**
    * @dev Called by anyone ONLY VIA THE ERC20 TOKEN CONTRACT to decrease their stake.
    * @param staker The address of the staker that wants to withdraw their stake.
    * @param amountToken Number of tokens to withdraw.
    * @return success True if the operation completed successfully.
    **/
    function decreaseStake(address staker, uint256 amountToken) external returns (bool success);

    /**
    * @dev Called by participant to make a new prediction submission for the current challenge.
    * @dev Will be successful if the participant's stake is above the staking threshold.
    * @param submissionHash IPFS reference hash of submission. This is the IPFS CID less the 1220 prefix.
    * @return challengeNumber Challenge that this submission was made for.
    **/
    function submitNewPredictions(bytes32 submissionHash) external returns (uint32 challengeNumber);

    /**
    * @dev Called by participant to modify prediction submission for the current challenge.
    * @param oldSubmissionHash IPFS reference hash of previous submission. This is the IPFS CID less the 1220 prefix.
    * @param newSubmissionHash IPFS reference hash of new submission. This is the IPFS CID less the 1220 prefix.
    * @return challengeNumber Challenge that this submission was made for.
    **/
    function updateSubmission(bytes32 oldSubmissionHash, bytes32 newSubmissionHash) external returns (uint32 challengeNumber);

    /**
    ORGANIZER WRITE METHODS
    **/

    /**
    * @dev Called only by authorized admin to update the current broadcast message.
    * @param newMessage New broadcast message.
    * @return success True if the operation completed successfully.
    **/
    function updateMessage(string calldata newMessage) external  returns (bool success);

    /**
    * @dev Called only by authorized admin to update one of the deadlines for this challenge.
    * @param challengeNumber Challenge to perform the update for.
    * @param index Deadline index to update.
    * @param timestamp Deadline timestamp in milliseconds.
    * @return success True if the operation completed successfully.
    **/
    function updateDeadlines(uint32 challengeNumber, uint256 index, uint256 timestamp) external returns (bool success);

    /**
    * @dev Called only by authorized admin to update the minimum amount required in the competition rewards pool to open a new challenge.
    * @param newThreshold New minimum amount for opening new challenge.
    * @return success True if the operation completed successfully.
    **/
    function updateRewardsThreshold(uint256 newThreshold) external returns (bool success);

    /**
    * @dev Called only by authorized admin to update the minimum stake amount required to take part in the competition.
    * @param newStakeThreshold New stake threshold amount in wei.
    * @return success True if the operation completed successfully.
    **/
    function updateStakeThreshold(uint256 newStakeThreshold) external returns (bool success);

    /**
    * @dev Called only by authorized admin to update the percentage of the competition rewards pool allocated to the challenge rewards budget.
    * @param newPercentage New percentage amount in wei.
    * @return success True if the operation completed successfully.
    **/
    function updateChallengeRewardsPercentageInWei(uint256 newPercentage) external returns (bool success);

    /**
    * @dev Called only by authorized admin to update the percentage of the competition rewards pool allocated to the tournament rewards budget.
    * @param newPercentage New percentage amount in wei.
    * @return success True if the operation completed successfully.
    **/
    function updateTournamentRewardsPercentageInWei(uint256 newPercentage) external returns (bool success);

    /**
    * @dev Called only by authorized admin to update the private key for this challenge. This should be done at the end of the challenge.
    * @param challengeNumber Challenge to perform the update for.
    * @param newKeyHash IPFS reference cid where private key is stored.
    * @return success True if the operation completed successfully.
    **/
    function updatePrivateKey(uint32 challengeNumber, bytes32 newKeyHash) external returns (bool success);

    /**
    * @dev Called only by authorized admin to start allowing staking for a new challenge.
    * @param datasetHash IPFS reference hash where dataset for this challenge is stored. This is the IPFS CID less the 1220 prefix.
    * @param keyHash IPFS reference hash where the key for this challenge is stored. This is the IPFS CID less the 1220 prefix.
    * @param submissionCloseDeadline Timestamp of the time where submissions will be closed.
    * @param nextChallengeDeadline Timestamp where ths challenge will be closed and the next challenge opened.
    * @return success True if the operation completed successfully.
    **/
    function openChallenge(bytes32 datasetHash, bytes32 keyHash, uint256 submissionCloseDeadline, uint256 nextChallengeDeadline) external returns (bool success);

    /**
    * @dev Called only by authorized admin to update the IPFS reference for the dataset of a particular challenge.
    * @param oldDatasetHash IPFS reference hash where previous dataset for this challenge is stored. This is the IPFS CID less the 1220 prefix.
    * @param newDatasetHash IPFS reference hash where new dataset for this challenge is stored. This is the IPFS CID less the 1220 prefix.
    * @return success True if the operation completed successfully.
    **/
    function updateDataset(bytes32 oldDatasetHash, bytes32 newDatasetHash) external returns (bool success);

    /**
    * @dev Called only by authorized admin to update the IPFS reference for the key of a particular challenge.
    * @param oldKeyHash IPFS reference hash where previous key for this challenge is stored. This is the IPFS CID less the 1220 prefix.
    * @param newKeyHash IPFS reference hash where new key for this challenge is stored. This is the IPFS CID less the 1220 prefix.
    * @return success True if the operation completed successfully.
    **/
    function updateKey(bytes32 oldKeyHash, bytes32 newKeyHash) external returns (bool success);

    /**
    * @dev Called only by authorized admin to stop allowing submissions for a particular challenge.
    * @return success True if the operation completed successfully.
    **/
    function closeSubmission() external returns (bool success);

    /**
    * @dev Called only by authorized admin to submit the IPFS reference for the results of a particular challenge.
    * @param resultsHash IPFS reference hash where results for this challenge are stored. This is the IPFS CID less the 1220 prefix.
    * @return success True if the operation completed successfully.
    **/
    function submitResults(bytes32 resultsHash) external returns (bool success);

    /**
    * @dev Called only by authorized admin to update the IPFS reference for the results of the current challenge.
    * @param oldResultsHash IPFS reference hash where previous results for this challenge are stored. This is the IPFS CID less the 1220 prefix.
    * @param newResultsHash IPFS reference hash where new results for this challenge are stored. This is the IPFS CID less the 1220 prefix.
    * @return success True if the operation completed successfully.
    **/
    function updateResults(bytes32 oldResultsHash, bytes32 newResultsHash) external returns (bool success);

    /**
    * @dev Called only by authorized admin to move rewards from the competition pool to the winners' competition internal balances based on results from the current challenge.
    * @dev Note that the size of the array parameters passed in to this function is limited by the block gas limit.
    * @dev This function allows for the payout to be split into chunks by calling it repeatedly.
    * @param submitters List of addresses that made submissions for the challenge.
    * @param stakingRewards List of corresponding amount of tokens in wei given to each submitter for the staking rewards portion.
    * @param challengeRewards List of corresponding amount of tokens in wei won by each submitter for the challenge rewards portion.
    * @param tournamentRewards List of corresponding amount of tokens in wei won by each submitter for the tournament rewards portion.
    * @return success True if operation completes successfully.
    **/
    function payRewards(address[] calldata submitters, uint256[] calldata stakingRewards, uint256[] calldata challengeRewards, uint256[] calldata tournamentRewards) external returns (bool success);

    /**
    * @dev Provides the same function as above but allows for challenge number to be specified.
    * @dev Note that the size of the array parameters passed in to this function is limited by the block gas limit.
    * @dev This function allows for the update to be split into chunks by calling it repeatedly.
    * @param challengeNumber Challenge to make updates for.
    * @param participants List of participants' addresses.
    * @param challengeScores List of corresponding challenge scores.
    * @param tournamentScores List of corresponding tournament scores.
    * @return success True if operation completes successfully.
    **/
    function updateChallengeAndTournamentScores(uint32 challengeNumber, address[] calldata participants, uint256[] calldata challengeScores, uint256[] calldata tournamentScores) external returns (bool success);

    /**
    * @dev Called only by authorized admin to do a batch update of an additional information item for a list of participants for a given challenge.
    * @param challengeNumber Challenge to update information for.
    * @param participants List of participant' addresses.
    * @param itemNumber Item to update for.
    * @param values List of corresponding values to store.
    * @return success True if operation completes successfully.
    **/
    function updateInformationBatch(uint32 challengeNumber, address[] calldata participants, uint256 itemNumber, uint[] calldata values) external returns (bool success);

    /**
    * @dev Called only by an authorized admin to advance to the next phase.
    * @dev Due to the block gas limit rewards payments may need to be split up into multiple function calls.
    * @dev In other words, payStakingRewards and payChallengeAndTournamentRewards may need to be called multiple times to complete all required payments.
    * @dev This function is used to advance to phase 3 after staking rewards payments have complemted or to phase 4 after challenge and tournament rewards payments have completed.
    * @param phase The phase to advance to.
    * @return success True if the operation completed successfully.
    **/
    function advanceToPhase(uint8 phase) external returns (bool success);

    /**
    * @dev Called only by an authorized admin, to move any tokens sent to this contract without using the 'sponsor' or 'setStake'/'increaseStake' methods into the competition pool.
    * @return success True if the operation completed successfully.
    **/
    function moveRemainderToPool() external returns (bool success);

    /**
    READ METHODS
    **/

    /**
    * @dev Called by anyone to check minimum amount required to open a new challenge.
    * @return challengeRewardsThreshold Amount of tokens in wei the competition pool must contain to open a new challenge.
    **/
    function getRewardsThreshold() view external returns (uint256 challengeRewardsThreshold);

    /**
    * @dev Called by anyone to check amount pooled into this contract.
    * @return competitionPool Amount of tokens in the competition pool in wei.
    **/
    function getCompetitionPool() view external returns (uint256 competitionPool);

    /**
    * @dev Called by anyone to check the current total amount staked.
    * @return currentTotalStaked Amount of tokens currently staked in wei.
    **/
    function getCurrentTotalStaked() view external returns (uint256 currentTotalStaked);

    /**
    * @dev Called by anyone to check the staking rewards budget allocation for the current challenge.
    * @return currentStakingRewardsBudget Budget for staking rewards in wei.
    **/
    function getCurrentStakingRewardsBudget() view external returns (uint256 currentStakingRewardsBudget);

    /**
    * @dev Called by anyone to check the challenge rewards budget for the current challenge.
    * @return currentChallengeRewardsBudget Budget for challenge rewards payment in wei.
    **/
    function getCurrentChallengeRewardsBudget() view external returns (uint256 currentChallengeRewardsBudget);

    /**
    * @dev Called by anyone to check the tournament rewards budget for the current challenge.
    * @return currentTournamentRewardsBudget Budget for tournament rewards payment in wei.
    **/
    function getCurrentTournamentRewardsBudget() view external returns (uint256 currentTournamentRewardsBudget);

    /**
    * @dev Called by anyone to check the percentage of the total competition reward pool allocated for the challenge reward for this challenge.
    * @return challengeRewardsPercentageInWei Percentage for challenge reward budget in wei.
    **/
    function getChallengeRewardsPercentageInWei() view external returns (uint256 challengeRewardsPercentageInWei);

    /**
    * @dev Called by anyone to check the percentage of the total competition reward pool allocated for the tournament reward for this challenge.
    * @return tournamentRewardsPercentageInWei Percentage for tournament reward budget in wei.
    **/
    function getTournamentRewardsPercentageInWei() view external returns (uint256 tournamentRewardsPercentageInWei);

    /**
    * @dev Called by anyone to get the number of the latest challenge.
    * @dev As the challenge number begins from 1, this is also the total number of challenges created in this competition.
    * @return latestChallengeNumber Latest challenge created.
    **/
    function getLatestChallengeNumber() view external returns (uint32 latestChallengeNumber);

    /**
    * @dev Called by anyone to obtain the dataset hash for this particular challenge.
    * @param challengeNumber The challenge to get the dataset hash of.
    * @return dataset IPFS hash where the dataset of this particular challenge is stored. This is the IPFS CID less the 1220 prefix.
    **/
    function getDatasetHash(uint32 challengeNumber) view external returns (bytes32 dataset);

    /**
    * @dev Called by anyone to obtain the results hash for this particular challenge.
    * @param challengeNumber The challenge to get the results hash of.
    * @return results IPFS hash where results of this particular challenge are stored. This is the IPFS CID less the 1220 prefix.
    **/
    function getResultsHash(uint32 challengeNumber) view external returns (bytes32 results);

    /**
    * @dev Called by anyone to obtain the key hash for this particular challenge.
    * @param challengeNumber The challenge to get the key hash of.
    * @return key IPFS hash where results of this particular challenge are stored. This is the IPFS CID less the 1220 prefix.
    **/
    function getKeyHash(uint32 challengeNumber) view external returns (bytes32 key);

    /**
    * @dev Called by anyone to obtain the private key hash for this particular challenge.
    * @param challengeNumber The challenge to get the key hash of.
    * @return privateKey IPFS hash where results of this particular challenge are stored. This is the IPFS CID less the 1220 prefix.
    **/
    function getPrivateKeyHash(uint32 challengeNumber) view external returns (bytes32 privateKey);

    /**
    * @dev Called by anyone to obtain the number of submissions made for this particular challenge.
    * @param challengeNumber The challenge to get the submission counter of.
    * @return submissionCounter Number of submissions made.
    **/
    function getSubmissionCounter(uint32 challengeNumber) view external returns (uint256 submissionCounter);

    /**
    * @dev Called by anyone to obtain the list of submitters for this particular challenge.
    * @dev Submitters refer to participants that have made submissions for this particular challenge.
    * @param challengeNumber The challenge to get the submitters list of.
    * @param startIndex The challenge to get the submitters list of.
    * @param endIndex The challenge to get the submitters list of.
    * @return List of submitter addresses.
    **/
    function getSubmitters(uint32 challengeNumber, uint8 startIndex, uint8 endIndex) view external returns (address[] memory);

    /**
    * @dev Called by anyone to obtain the phase number for this particular challenge.
    * @param challengeNumber The challenge to get the phase of.
    * @return phase The phase that this challenge is in.
    **/
    function getPhase(uint32 challengeNumber) view external returns (uint8 phase);

    /**
    * @dev Called by anyone to obtain the minimum amount of stake required to participate in the competition.
    * @return stakeThreshold Minimum stake amount in wei.
    **/
    function getStakeThreshold() view external returns (uint256 stakeThreshold);

    /**
    * @dev Called by anyone to obtain the stake amount in wei of a particular address.
    * @param participant Address to query token balance of.
    * @return stake Token balance of given address in wei.
    **/
    function getStake(address participant) view external returns (uint256 stake);

    /**
    * @dev Called by anyone to obtain the smart contract address of the ERC20 token used in this competition.
    * @return tokenAddress ERC20 Token smart contract address.
    **/
    function getTokenAddress() view external returns (address tokenAddress);

    /**
    * @dev Called by anyone to get submission hash of a participant for a challenge.
    * @param challengeNumber Challenge index to check on.
    * @param participant Address of participant to check on.
    * @return submissionHash IPFS reference hash of participant's prediction submission for this challenge. This is the IPFS CID less the 1220 prefix.
    **/
    function getSubmission(uint32 challengeNumber, address participant) view external returns (bytes32 submissionHash);

    /**
    * @dev Called by anyone to check the stakes locked for this participant in a particular challenge.
    * @param challengeNumber Challenge to get the stakes locked of.
    * @param participant Address of participant to check on.
    * @return staked Amount of tokens locked for this challenge for this participant.
    **/
    function getStakedAmountForChallenge(uint32 challengeNumber, address participant) view external returns (uint256 staked);

    /**
    * @dev Called by anyone to check the staking rewards given to this participant in a particular challenge.
    * @param challengeNumber Challenge to get the staking rewards given of.
    * @param participant Address of participant to check on.
    * @return stakingRewards Amount of staking rewards given to this participant for this challenge.
    **/
    function getStakingRewards(uint32 challengeNumber, address participant) view external returns (uint256 stakingRewards);

    /**
    * @dev Called by anyone to check the challenge rewards given to this participant in a particular challenge.
    * @param challengeNumber Challenge to get the challenge rewards given of.
    * @param participant Address of participant to check on.
    * @return challengeRewards Amount of challenge rewards given to this participant for this challenge.
    **/
    function getChallengeRewards(uint32 challengeNumber, address participant) view external returns (uint256 challengeRewards);

    /**
    * @dev Called by anyone to check the tournament rewards given to this participant in a particular challenge.
    * @param challengeNumber Challenge to get the tournament rewards given of.
    * @param participant Address of participant to check on.
    * @return tournamentRewards Amount of tournament rewards given to this participant for this challenge.
    **/
    function getTournamentRewards(uint32 challengeNumber, address participant) view external returns (uint256 tournamentRewards);

    /**
    * @dev Called by anyone to check the overall rewards (staking + challenge + tournament rewards) given to this participant in a particular challenge.
    * @param challengeNumber Challenge to get the overall rewards given of.
    * @param participant Address of participant to check on.
    * @return overallRewards Amount of overall rewards given to this participant for this challenge.
    **/
    function getOverallRewards(uint32 challengeNumber, address participant) view external returns (uint256 overallRewards);

    /**
    * @dev Called by anyone to check get the challenge score of this participant for this challenge.
    * @param challengeNumber Challenge to get the participant's challenge score of.
    * @param participant Address of participant to check on.
    * @return challengeScores The challenge score of this participant for this challenge.
    **/
    function getChallengeScores(uint32 challengeNumber, address participant) view external returns (uint256 challengeScores);

    /**
    * @dev Called by anyone to check get the tournament score of this participant for this challenge.
    * @param challengeNumber Challenge to get the participant's tournament score of..
    * @param participant Address of participant to check on.
    * @return tournamentScores The tournament score of this participant for this challenge.
    **/
    function getTournamentScores(uint32 challengeNumber, address participant) view external returns (uint256 tournamentScores);

    /**
    * @dev Called by anyone to check the additional information for this participant in a particular challenge.
    * @param challengeNumber Challenge to get the additional information of.
    * @param participant Address of participant to check on.
    * @param itemNumber Additional information item to check on.
    * @return value Value of this additional information item for this participant for this challenge.
    **/
    function getInformation(uint32 challengeNumber, address participant, uint256 itemNumber) view external returns (uint value);

    /**
    * @dev Called by anyone to retrieve one of the deadlines for this challenge.
    * @param challengeNumber Challenge to get the deadline of.
    * @param index Index of the deadline to retrieve.
    * @return deadline Deadline in milliseconds.
    **/
    function getDeadlines(uint32 challengeNumber, uint256 index)
    external view returns (uint256 deadline);

    /**
    * @dev Called by anyone to check the amount of tokens that have been sent to this contract but are not recorded as a stake or as part of the competition rewards pool.
    * @return remainder The amount of tokens held by this contract that are not recorded as a stake or as part of the competition rewards pool.
    **/
    function getRemainder() external view returns (uint256 remainder);

    /**
    * @dev Called by anyone to get the current broadcast message.
    * @return message Current message being broadcasted.
    **/
    function getMessage() external returns (string memory message);

    /**
    METHODS CALLABLE BY BOTH ADMIN AND PARTICIPANTS.
    **/

    /**
    * @dev Called by a sponsor to send tokens to the contract's competition pool. This pool is used for payouts to challenge winners.
    * @dev This performs an ERC20 transfer so the msg sender will need to grant approval to this contract before calling this function.
    * @param amountToken The amount to send to the the competition pool.
    * @return success True if the operation completed successfully.
    **/
    function sponsor(uint256 amountToken) external returns (bool success);

    /**
    EVENTS
    **/

    event StakeIncreased(address indexed sender, uint256 indexed amount);

    event StakeDecreased(address indexed sender, uint256 indexed amount);

    event SubmissionUpdated(uint32 indexed challengeNumber, address indexed participantAddress, bytes32 indexed newSubmissionHash);

    event MessageUpdated();

    event RewardsThresholdUpdated(uint256 indexed newRewardsThreshold);

    event StakeThresholdUpdated(uint256 indexed newStakeThreshold);

    event ChallengeRewardsPercentageInWeiUpdated(uint256 indexed newPercentage);

    event TournamentRewardsPercentageInWeiUpdated(uint256 indexed newPercentage);

    event PrivateKeyUpdated(bytes32 indexed newPrivateKeyHash);

    event ChallengeOpened(uint32 indexed challengeNumber);

    event DatasetUpdated(uint32 indexed challengeNumber, bytes32 indexed oldDatasetHash, bytes32 indexed newDatasetHash);

    event KeyUpdated(uint32 indexed challengeNumber, bytes32 indexed oldKeyHash, bytes32 indexed newKeyHash);

    event SubmissionClosed(uint32 indexed challengeNumber);

    event ResultsUpdated(uint32 indexed challengeNumber, bytes32 indexed oldResultsHash, bytes32 indexed newResultsHash);

    event RewardsPayment(uint32 challengeNumber, address indexed submitter, uint256 stakingReward, uint256 indexed challengeReward, uint256 indexed tournamentReward);

    event TotalRewardsPaid(uint32 challengeNumber, uint256 indexed totalStakingAmount, uint256 indexed totalChallengeAmount, uint256 indexed totalTournamentAmount);

    event ChallengeAndTournamentScoresUpdated(uint32 indexed challengeNumber);

    event BatchInformationUpdated(uint32 indexed challengeNumber, uint256 indexed itemNumber);

    event RemainderMovedToPool(uint256 indexed remainder);

    event Sponsor(address indexed sponsorAddress, uint256 indexed sponsorAmount, uint256 indexed poolTotal);
}