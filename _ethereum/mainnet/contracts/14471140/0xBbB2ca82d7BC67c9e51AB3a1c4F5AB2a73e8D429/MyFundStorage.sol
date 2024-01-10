// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "LinkTokenInterface.sol";
import "VRFCoordinatorV2Interface.sol";
import "VRFConsumerBaseV2.sol";
import "Ownable.sol";
import "EthUsPriceConversion.sol";

contract MyFundStorage is VRFConsumerBaseV2, Ownable {

    address payable[] internal payers;

    EthUsPriceConversion internal ethUsConvert;

    enum FUNDING_STATE {
        OPEN,
        END,
        CLOSED
    }
    FUNDING_STATE internal funding_state;

    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    // VRF subscription ID.
   // uint64 subscriptionId;
    uint64 subscriptionId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    bytes32 keyHash;

    // Minimum Entry Fee to fund
    uint256 minimumEntreeFee;

    // Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. 
    uint32 callbackGasLimit;

    // The default is 3.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 2;

    uint256[] randomWords;
    uint256 requestId;
    address s_owner;
 
    event ReturnedRandomness_Funding_begin(uint256 requestId);
    event ReturnedRandomness_Funding_end(uint256 requestId);
    event ReturnedRandomness_endFunding_begin(uint256 requestId);
    event ReturnedRandomness_endFunding_end(uint256 requestId);
    event ReturnedRandomness_withdraw_begin(uint256 requestId);
    event ReturnedRandomness_withdraw_end(uint256 requestId);
    event ReturnedRandomness_fulfill_begin(uint256 requestId);
    event ReturnedRandomness_fulfill_end(uint256 requestId);
    event ReturnedRandomness_requestRandomWord_begin(uint256 requestId);
    event ReturnedRandomness_requestRandomWord_end(uint256 requestId);
    
    /**
     * @notice Constructor inherits VRFConsumerBaseV2
     *
     * @param _subscriptionId - the subscription ID that this contract uses for funding requests
     * @param _vrfCoordinator - coordinator
     * @param _keyHash - the gas lane to use, which specifies the maximum gas price to bump to
     */
    constructor(
        address _priceFeedAddress,
        uint256 _minimumEntreeFee,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(_vrfCoordinator) payable{
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(_link);
        minimumEntreeFee = _minimumEntreeFee;
        ethUsConvert = new EthUsPriceConversion(_priceFeedAddress, minimumEntreeFee);
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        s_owner = msg.sender;
        subscriptionId = _subscriptionId;
        funding_state = FUNDING_STATE.CLOSED;
    }

    /**
     * @notice Get the current Ethereum market price in Wei
     */
    function getETHprice() external view returns (uint256) {
       return ethUsConvert.getETHprice();
    }

    /**
     * @notice Get the current Ethereum market price in US Dollar
     */
    function getETHpriceUSD() external view returns (uint256) {
        return ethUsConvert.getETHpriceUSD();
    }

    /**
     * @notice Get the minimum funding amount which is $50
     */
    function getEntranceFee() external view returns (uint256) {
        return ethUsConvert.getEntranceFee();
    }

    /**
     * @notice Update the gas limit for callback function 
     */
    function updateCallbackGasLimit(uint32 gasLimit) external onlyOwner {
        callbackGasLimit = gasLimit;
    }

    /**
     * @notice Update minimum funding amount
     */
    function updateMinimumEntryFee(uint256 min_Entree_Fee) external onlyOwner {
        minimumEntreeFee = min_Entree_Fee;
    }

    /**
     * @notice Update the funding state
     */
    function updateFundingState(FUNDING_STATE _funding_state) external onlyOwner {
        funding_state = _funding_state;
    }

    /**
     * @notice Get the Random RequestID from Chainlink
     */
    function getRandomRequestID() external view returns (uint256) {
        return requestId;
    }

    /**
     * @notice Get the First Random Word Response from Chainlink
     */
    function getFirstRandomWord() external view returns (uint256) {
        return randomWords[0];
    }

    /**
     * @notice Get the Second Random Word Response from Chainlink
     */
    function getSecondRandomWord() external view returns (uint256) {
        return randomWords[1];
    }

    /**
     * @notice Open the funding account.  Users can start funding now.
     */
    function startFunding() external onlyOwner {
        require(
            funding_state == FUNDING_STATE.CLOSED,
            "Can't start a new fund yet! Current funding is not closed yet!"
        );
        funding_state = FUNDING_STATE.OPEN;
    }

    /**
     * @notice User can enter the fund.  Minimum $50 value of ETH.
     */
    function fund() external payable {
        // $50 minimum
        emit ReturnedRandomness_Funding_begin(requestId);
        require(funding_state == FUNDING_STATE.OPEN, "Can't fund yet.  Funding is not opened yet.");
        require(msg.value >= ethUsConvert.getEntranceFee(), "Not enough ETH! Minimum $50 value of ETH require!");
        payers.push(payable(msg.sender));
        emit ReturnedRandomness_Funding_end(requestId);
    }

    /**
     * @notice Get current funding state.
     */
    function getCurrentFundingState() external view returns (FUNDING_STATE) {
        return funding_state;
    }

    /**
     * @notice Get the total amount that users funding in this account.
     */
    function getUsersTotalAmount() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Funding is ended.
     */
    function endFunding() external onlyOwner {
        emit ReturnedRandomness_endFunding_begin(requestId);
        require(funding_state == FUNDING_STATE.OPEN, "Funding is not opened yet.");
        funding_state = FUNDING_STATE.END;
        emit ReturnedRandomness_endFunding_end(requestId);
    }

    /**
     * @notice Owner withdraw the funding.
     */
    function withdraw() external onlyOwner {
        emit ReturnedRandomness_withdraw_begin(requestId);
        require(
            funding_state == FUNDING_STATE.END,
            "Funding must be ended before withdraw!"
        );
        requestRandomWords();
        funding_state = FUNDING_STATE.CLOSED;
        emit ReturnedRandomness_withdraw_end(requestId);
    }

    /**
     * @notice Owner withdraw the funding.
     */
    function withdraw2() external onlyOwner {
        emit ReturnedRandomness_withdraw_begin(requestId);
        require(
            funding_state == FUNDING_STATE.END,
            "Funding must be ended before withdraw!"
        );
        payable(s_owner).transfer(address(this).balance);
        payers = new address payable[](0);
        funding_state = FUNDING_STATE.CLOSED;
        emit ReturnedRandomness_withdraw_end(requestId);
    }


    /**
    * @notice Requests randomness
    * Assumes the subscription is funded sufficiently; "Words" refers to unit of data in Computer Science
     */
    function requestRandomWords() internal {
    // Will revert if subscription is not set and funded.
        emit ReturnedRandomness_requestRandomWord_begin(requestId);
        requestId = COORDINATOR.requestRandomWords(
        keyHash,
        subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
        );
        emit ReturnedRandomness_requestRandomWord_end(requestId);
    }

    /*
    * @notice Callback function used by VRF Coordinator
    *
    * @param requestId - id of the request
    * @param randomWords - array of random results from VRF Coordinator
    */
    function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory _randomWords
    ) internal override { 
        emit ReturnedRandomness_fulfill_begin(requestId);
        randomWords = _randomWords;

        payable(s_owner).transfer(address(this).balance);
        payers = new address payable[](0);
        funding_state = FUNDING_STATE.CLOSED;
        emit ReturnedRandomness_fulfill_end(requestId);
    }
  }