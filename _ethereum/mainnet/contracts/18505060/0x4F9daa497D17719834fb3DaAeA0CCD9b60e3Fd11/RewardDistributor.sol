// File: IVRFv2DirectFundingConsumer.sol



pragma solidity ^0.8.21;
interface IVRFv2DirectFundingConsumer{
        function getRequestStatus(uint256 _requestId) external view returns (uint256 paid, bool fulfilled, uint256[] memory randomWords);
        function requestRandomWords(uint32 numWords) external returns (uint256 requestId);
}
// File: IRoleRegistry.sol

pragma solidity ^0.8.21;


interface IRoleRegistry{
    function getRouter() external view returns(address);
    function getOwner() external view returns(address);
    function getController() external view returns(address);
    function getRewardDistributor() external view returns(address);
    function getOperator() external view returns(address);
    function getVRF() external view returns(address);
    function getReserveAddress() external view returns(address);
}
// File: IMutualPool.sol



pragma solidity ^0.8.21;




interface IMutualPool{
    event rewardPortionUpdated(uint256 first, uint256 second, uint256 third);
    event OwnershipTransferred(address oldOwner, address newOwner);
    event ControllerRoleTransferred(address oldController, address newController);
    event changedRouter(address oldRouter, address newRouter);


    struct PrizeDetails{
        address winner;
        uint256 prizeAmount;
        bool claimed;
    }
    struct EpochResult{
        PrizeDetails first;
        PrizeDetails second;
        PrizeDetails third;
        bool finalized;
        uint256 totalPrize;
        uint256 duration;
        uint256 createdTimeStamp;
        uint256 totalParticipant;
    }

    struct rewardAllocation{
        uint256 first;
        uint256 second;
        uint256 third;
    }
    struct userInfo{
        address userAddress;
        uint256 DepositAmount;
        uint256 registeredDate;
        uint256 Lastupdated;
        //uint256 depositTimeStamp;
    }
    struct ChangeArray{
        uint256 oldAmount;
        uint256 newAmount;
        uint256 updatedBlock;
    }
    struct userChangeHistory{
        bool changedwithinEpoch;
        ChangeArray[] historyArray;
    }
    struct rewardHistory{
        uint256 EpochNumber;
        uint256 position;
        uint256 PrizeAmount;
    }
    struct claimableRewardInfo{
        uint256 claimable;
        rewardHistory[] rewardHistoryArray;
    }


    function initialize(address registryAddress) external;
    function changeRegistryContractAddr(address registryAddress) external;

    /*Only Router functions */
    function depositFor(address user, uint256 amount) external;
    function withdrawFor(address user, uint256 amount) external;
    function claimRewardsFor(address user) external returns(uint256);


    /*View Area*/
    function getPoolTVL() external view returns(uint256);
    function getCurrentEpochReward() external view returns(uint256);
    function getClaimable(address user) external view returns(uint256);
    
    function getWinningHistory(address user) external view returns(rewardHistory[] memory);
    function getBalanceChangeHistory(address user, uint256 epochNumber) external view returns(userChangeHistory memory);
    function getUserID(address user) external view returns(uint256);

    function getUserAmount() external view returns(uint256);
    function getuserByID(uint256 userID) external view returns(address);
    function getUserDepositInfo(address user) external view returns(userInfo memory);
    function getAccumulatedTicketwithoutDecimal(uint256 epochNumber, address user) external view returns(uint256);
    function getTicketAmount(uint256 epochNumber, address user) external view returns(uint256);
    function getTokenUsing() external view returns(address);
    function getLatestEpoch() external view returns(uint256);
    function getEpochLength() external view returns(uint256);
    function getEpochInfo(uint256 epochNumber) external view returns(EpochResult memory);
    function getRewardAllocationPercentage() external view returns(rewardAllocation memory);
    function getMinAmountToDeposit() external view returns(uint256);

    
    function setToken(address token) external;
    function setTicketDecimal(uint256 decimal) external;
    function setStakePoolAddress(address StakePoolAdd) external;
    function setEpochDuration(uint256 duration) external;
    function setMinAmounttoDeposit(uint256 amount) external;
    function setRewardRatio(uint256 firstP, uint256 secondP, uint256 thirdP, uint256 percentageSUM) external;
    
    function finalizeEpochTicketandParticipantInfo(uint256 epochNumber) external;
    function finalizeEpoch(uint256 epochNumber, address firstWinner, address secondWinner, address thirdWinner, uint256 totalPrize) external;

    function createNewEpoch() external;
    function claimRewardFromPool() external returns(uint256);
    

}



// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: RewardDistributor.sol

pragma solidity ^0.8.21;






contract RewardDistributor{

    struct RandomnessRequest{
        address poolAddress;
        uint256 epochNumber;
        uint256 DrawRequestID;
        uint256 thisDrawTicketAmount;
        uint32 randomWordsAmount;
        bool fulfilled;
        uint256[] results;
    }
    address registryContract;
    bool initialized;
    uint256 currentDrawRequestID;
    uint256 thisDrawTicketAmount;
    RandomnessRequest[] randomnessHistory;
    modifier onlyOwner(){
        address role = IRoleRegistry(registryContract).getOwner();
        require(msg.sender == role, "Invalid caller");
        _;
    }

    

    modifier onlyOperator(){
        address role = IRoleRegistry(registryContract).getOperator();
        require(msg.sender == role, "Invalid caller");
        _;
    }

    function initialize(address registryAddress) external{
        require(initialized == false, "Contract is initialized already");
        _transferRegistryAddr(registryAddress);
        initialized = true;
    }

    function _transferRegistryAddr(address registryAddress) internal{
        registryContract = registryAddress;
    }

    function changeRegistryContractAddr(address registryAddress) external onlyOwner{
        _transferRegistryAddr(registryAddress);
    }

    function genesisEpochInitialize(address poolAddress) external onlyOperator{
        IMutualPool(poolAddress).createNewEpoch();
    }

    function SumUpandClaimPrizeEpoch(address poolAddress, uint256 epochNumber, bool manualClaimreward) external onlyOperator returns(uint256){
        uint256 rewardclaimed;
        IMutualPool(poolAddress).finalizeEpochTicketandParticipantInfo(epochNumber);
        if(manualClaimreward){
            rewardclaimed = IMutualPool(poolAddress).claimRewardFromPool();
        }
        else{
            rewardclaimed = IMutualPool(poolAddress).getCurrentEpochReward();
        }
        return rewardclaimed;

    }

    function requestRandomness(address poolAddress,uint256 epochNumber, uint256 TotalTicketAmount,uint32 randomWordsAmount) external onlyOperator returns(uint256){

        address VRFAddress = IRoleRegistry(registryContract).getVRF();
        uint256 requestID = IVRFv2DirectFundingConsumer(VRFAddress).requestRandomWords(randomWordsAmount);

        randomnessHistory.push(RandomnessRequest({
            poolAddress: poolAddress,
            epochNumber: epochNumber,
            DrawRequestID: requestID,
            thisDrawTicketAmount: TotalTicketAmount,
            randomWordsAmount: randomWordsAmount,
            fulfilled: false,
            results: new uint256[](3)
        }));


        uint256 result = randomnessHistory.length - 1;
        return result;
    }


    
    function comeupwithThisDrawLuckyUsers(uint256 requestHistoryID) external onlyOperator returns(uint256[] memory){
        
        uint256 requestID = randomnessHistory[requestHistoryID].DrawRequestID;
        uint256 totalTicketAmount = randomnessHistory[requestHistoryID].thisDrawTicketAmount;
        address VRFAddress = IRoleRegistry(registryContract).getVRF();
        (, bool fulfilled, uint256[] memory randomWords) = IVRFv2DirectFundingConsumer(VRFAddress).getRequestStatus(requestID);
        require(fulfilled,"The randomness request is not fulfilled, please wait a bit more");
        for(uint i = 0;i<randomWords.length;i++){
            randomnessHistory[requestHistoryID].results[i] = randomWords[i] % totalTicketAmount;
        }
        randomnessHistory[requestHistoryID].fulfilled = true;

        return randomnessHistory[requestHistoryID].results;
    }
    

    function FinalizeAndCreateNewEpoch(address poolAddress, uint256 epochNumber, address firstWinner, address secondWinner, address thirdWinner, uint256 totalPrize)  external onlyOperator{
        IMutualPool(poolAddress).finalizeEpoch(epochNumber,firstWinner,secondWinner,thirdWinner,totalPrize);
        IMutualPool(poolAddress).createNewEpoch();
    }

    function getRandomnessHistory(uint256 requestHistoryID) public view returns(RandomnessRequest memory) {
        RandomnessRequest memory result = randomnessHistory[requestHistoryID];
        return result;
    }
    


}