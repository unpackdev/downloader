// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

/**
 * @title OnChainPoll Contract for OnChain Voting System
 * @author The Tech Alchemy Team
 * @notice You can use this contract for creation and ending of a poll, voters can claim their poll reward
 * @dev All function calls are currently implemented without side effects
 */

import "./OnChainPollVerifiable.sol";

contract OnChainPollV1 is OnChainPollVerifiable {

    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint32;

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
     * @param toknContractAddress - Address of the TOKN contract used for paying the poll fee and reward transfer.
     * @param poapContractAddress - Address of the POAP contract used for minting the NFT to voter.
     * @param adminWalletAddress - Address of the admin of the contract.
     * @param treasuryWalletAddress - Address of the treasury for handling funds.
     */

    function initialize(
        uint256 minFee,
        uint256 percentForBurn,
        uint256 percentForPlatform,
        uint256 feeForPoll,
        address toknContractAddress,
        address poapContractAddress,
        address adminWalletAddress,
        address treasuryWalletAddress
    ) public initializer 
        isZeroAddress(toknContractAddress) 
        isZeroAddress(poapContractAddress) 
        isZeroAddress(adminWalletAddress) 
        isZeroAddress(treasuryWalletAddress)
    {
        require(minFee > 0, "OnChainPoll: Minimum Fee is zero");
        require(
            (minFee.sub(1)) < feeForPoll,
            "OnChainPoll: Fee should be greater than minimum fee"
        );
        require(percentForBurn > 0, "OnChainPoll: Burn percent is zero");
        require(percentForPlatform > 0, "OnChainPoll: Tranfer percent is zero");
        burnPercent = percentForBurn;
        platformPercent = percentForPlatform;
        pollFee = feeForPoll;
        minPollFee = minFee;
        toknContract = ERC20BurnableUpgradeable(toknContractAddress);
        POAPContract = POAPInterface(poapContractAddress);
        isAdmin[adminWalletAddress] = true;
        treasuryAddress = treasuryWalletAddress;
        __Pausable_init();
        __Ownable_init();
        __ReentrancyGuard_init();
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
        require(
            isPollValid,
            "OnChainPoll: Invalid polls detail"
        );
        uint256 pollsLength = polls.length;
        uint256[] memory successPollIds = new uint256[](pollsLength); 
        uint256 totalBurnAmount = 0;
        uint256 totalPlatformFee = 0;
        for (uint8 index = 0; index < pollsLength; index++) {
            PollEndDetails calldata pollDetail = polls[index];
            endPollsDetail[pollDetail.pollId] = pollDetail;
            totalBurnAmount = totalBurnAmount.add((pollDetail.fee.mul(burnPercent)).div(MAX_PERCENTAGE));
            if(pollDetail.winnersMerkle == ZERO_BYTES_32){
                totalPlatformFee = totalPlatformFee.add((pollDetail.fee.mul(MAX_PERCENTAGE.sub(burnPercent))).div(MAX_PERCENTAGE));
            } else{
                totalPlatformFee = totalPlatformFee.add((pollDetail.fee.mul(platformPercent)).div(MAX_PERCENTAGE));
            } 
            successPollIds[index] = pollDetail.pollId; 
        }
        toknContract.burn(totalBurnAmount);
        require(
            toknContract.transfer(treasuryAddress, totalPlatformFee),
            "OnChainPoll: Transfer token error"
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
        PollClaimReward[] memory pollsReward
    ) public override whenNotPaused {
        (, , bool isClaimRewardValid) = verifyClaimAllRewardDetails(pollsReward);
        require(
            isClaimRewardValid,
            "OnChainPoll: Invalid reward claims detail"
        );
        uint256 pollsLength = pollsReward.length;
        uint256[] memory successPollIds = new uint256[](pollsLength); 
        uint256 totalTransferAmount = 0;
        for (uint8 index = 0; index < pollsLength; index++) {
            PollClaimReward memory pollRewardDetail = pollsReward[index];
            totalTransferAmount += pollRewardDetail.amount;
            isPollRewardClaimed[pollRewardDetail.pollId][_msgSender()] = true;
            successPollIds[index] = pollRewardDetail.pollId; 
        }
        if (totalTransferAmount > 0) {
            uint256 balanceOfContract = toknContract.balanceOf(address(this));
            require(
                balanceOfContract > totalTransferAmount,
                "OnChainPoll: Contract does not have sufficient balance"
            );
            require(
                toknContract.transfer(_msgSender(), totalTransferAmount),
                "OnChainPoll: Transfer token error"
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
        require(
            isClaimNFTValid,
            "OnChainPoll: Invalid NFT claims detail"
        );
        uint256 pollsLength = pollsClaimNFT.length;
        uint256[] memory successPollIds = new uint256[](pollsLength);
        uint256[] memory successTokenIds = new uint256[](pollsLength); 
        for (uint8 index = 0; index < pollsLength; index++) {
            PollClaimNFT calldata pollNFTDetail = pollsClaimNFT[index];
            isVoterNFTClaimed[pollNFTDetail.pollId][_msgSender()] = true;
            uint256 tokenId = POAPContract.mint(
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
            toknContract.balanceOf(address(this))
        );
        require(
            isValid,
            "OnChainPoll: Invalid winning competitions detail"
        );
        uint256 totalBurnAmount = 0;
        uint256 totalPlatformFee = 0;
        uint256 endCompetitionsLength = endCompetitionDetails.length;
        uint256[] memory successCompetitionIds = new uint256[](
           endCompetitionsLength
        ); 
        for (uint8 index = 0; index <endCompetitionsLength; index++) {
            EndCompetitionDetails calldata endCompetitionDetail = endCompetitionDetails[index];
            uint256 burnAmount = (endCompetitionDetail.amount.mul(burnPercent)).div(MAX_PERCENTAGE); 
            uint256 platformFee = (endCompetitionDetail.amount.mul(platformPercent)).div(MAX_PERCENTAGE);
            uint256 competitionWinningAmount = endCompetitionDetail.amount.sub(platformFee).sub(burnAmount);
            totalBurnAmount = totalBurnAmount.add(burnAmount);
            totalPlatformFee = totalPlatformFee.add(platformFee);
            uint256 endCompetitionsAddressLength = endCompetitionDetail.toAddress.length;
            uint256 individualWinnngAmount = competitionWinningAmount.div(endCompetitionsAddressLength);
            for (uint256 winnerIndex = 0; winnerIndex < endCompetitionsAddressLength; winnerIndex++) {
                competitionWinnings[endCompetitionDetail.competitionId][endCompetitionDetail.toAddress[winnerIndex]] = individualWinnngAmount;
                competitionWinningAmount = competitionWinningAmount.sub(individualWinnngAmount);
            }
            
            totalPlatformFee += competitionWinningAmount;

            successCompetitionIds[index] = endCompetitionDetail.competitionId;
        }
        toknContract.burn(totalBurnAmount);  
        require(
            toknContract.transfer(treasuryAddress, totalPlatformFee),
            "OnChainPoll: Transfer token error"
        );
        emit CompetitionsEnded(successCompetitionIds);
    }

    /**  
     * @dev Allows a user to claim multiple competition reward.
     * @param competitonIds An array of competition ids.
     */
    function claimCompetitionReward(uint256[] memory competitonIds) external override whenNotPaused nonReentrant{
        uint256 competitonIdsLength = competitonIds.length;
        require(
            competitonIdsLength > 0,
            "OnChainPoll: Competition Ids length is zero"
        );
        uint256 totalWinning = 0;
        for (uint256 index = 0; index < competitonIdsLength; index++) {
            require(
                competitionWinnings[competitonIds[index]][_msgSender()] > 0,
                "OnChainPoll: Not eligible for competition reward"
            );
            totalWinning += competitionWinnings[competitonIds[index]][_msgSender()];
            competitionWinnings[competitonIds[index]][_msgSender()] = 0;
        } 
        require(
            toknContract.transfer(_msgSender(), totalWinning),
            "OnChainPoll: Transfer token error"
        ); 
        emit ClaimCompetitionRewardSuccessful(competitonIds);
    } 

    /**
     * @notice This function will withdraw to treasury address of the contract. 
     * @dev Withdraw the TOKN from the contract.
     * @dev Only owner can call this function.
     * @param amount Sending TOKN amount.
     */
    function TOKNWithdraw(
        uint256 amount
    ) external override onlyOwner whenNotPaused nonReentrant { 
        uint256 balanceOfContract = toknContract.balanceOf(address(this)); 
        require(
            amount > 0,
            "OnChainPoll: Amount is zero"
        );
        require(
            balanceOfContract > (amount.sub(1)),
            "OnChainPoll: Contract does not have sufficient balance"
        );
        require(
            toknContract.transfer(treasuryAddress, amount),
            "OnChainPoll: Transfer token error"
        );
        emit TOKNWithdrawSuccessful(treasuryAddress);
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
            (minPollFee.sub(1)) < fee,
            "OnChainPoll: Fee should be greater than minimum fee"
        );
        require(fee != pollFee, "OnChainPoll: Fee shouldn't be same as previous");
        pollFee = fee;
        emit PollFeeUpdated(pollFee);
    }

    /**
     * @dev Updates the TOKN contract address with the specified address.
     * @dev Only owner or admin can call this function.
     * @param toknContractAddress The new address of the TOKN contract.
     */
    function updateTOKNContract(
        address toknContractAddress
    ) external override onlyAdminOrOwner whenNotPaused nonReentrant isZeroAddress(toknContractAddress){
        require(
            toknContractAddress != address(toknContract),
            "OnChainPoll: Same as pervious address"
        );
        toknContract = ERC20BurnableUpgradeable(toknContractAddress);
        emit TOKNContractUpdated(address(toknContract));
    }

    /**
     * @dev Updates the POAP contract address with the specified address.
     * @dev Only owner or admin can call this function.
     * @param POAPContractAddress The new address of the POAP contract.
     */
    function updatePOAPContract(
        address POAPContractAddress
    ) external override onlyAdminOrOwner whenNotPaused nonReentrant isZeroAddress(POAPContractAddress){
        require(
            POAPContractAddress != address(POAPContract),
            "OnChainPoll: Same as pervious address"
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
        require(percentForBurn > 0, "OnChainPoll: Burn percent is zero");
        require(
            percentForBurn != burnPercent,
            "OnChainPoll: Burn percent shouldn't be same as previous"
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
    ) 
    external override onlyOwner whenNotPaused nonReentrant isZeroAddress(treasuryWalletAddress){
        require(
            treasuryWalletAddress != treasuryAddress,
            "OnChainPoll: Same as pervious address"
        );
        treasuryAddress = treasuryWalletAddress;
        emit TreasuryAddressUpdated(treasuryAddress);
    }

    /**
     * @dev Updates the transfer percent.
     * @dev Only owner can call this function.
     * @param percentForPlatform Percent of the token tranfer to treasury.
     */
    function updateTransferPercent(uint256 percentForPlatform) external override onlyOwner whenNotPaused nonReentrant {
        require(percentForPlatform > 0, "OnChainPoll: Tranfer percent is zero");
        require(
            platformPercent != percentForPlatform,
            "OnChainPoll: Tranfer percent shouldn't be same as previous"
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
    ) external override onlyOwner whenNotPaused nonReentrant isZeroAddress(addressOfAdmin){
        require(!isAdmin[addressOfAdmin], "OnChainPoll: Address already admin");
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
        require(isAdmin[addressOfAdmin], "OnChainPoll: Address not admin");
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
     * @dev Retrieves the burn percent of the TOKN.
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
     * @dev Retrieves the address of the TOKN contract.
     * @return toknContract The address of the TOKN contract.
     */
    function getTOKNAddress() external view override returns (address) {
        return address(toknContract);
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
            "OnChainPoll: Caller not admin or owner"
        );
        _;
    }

    /**
     * @notice isZeroAddress modifer to verify the address is not a zero address.
     */
    modifier isZeroAddress(address addressToVerify) {
        require(addressToVerify != ZERO_ADDRESS, "OnChainPoll: Address is the zero address");
        _;
    }
}