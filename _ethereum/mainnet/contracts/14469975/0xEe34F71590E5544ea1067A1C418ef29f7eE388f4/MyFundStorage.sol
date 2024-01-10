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
    uint64 s_subscriptionId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    bytes32 s_keyHash;

    // Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. 
    uint32 s_callbackGasLimit = 500000;

    // The default is 3.
    uint16 s_requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 s_numWords = 2;

    uint256[] internal s_randomWords;
    uint256 internal s_requestId;
    address s_owner;
 
    event ReturnedRandomness1_Funding_begin(uint256 requestId);
    event ReturnedRandomness1_Funding_end(uint256 requestId);
    event ReturnedRandomness1_endFunding_begin(uint256 requestId);
    event ReturnedRandomness1_endFunding_end(uint256 requestId);
    event ReturnedRandomness2_withdraw_begin(uint256 requestId);
    event ReturnedRandomness2_withdraw_end(uint256 requestId);
    event ReturnedRandomness3_fulfill_begin(uint256 requestId);
    event ReturnedRandomness3_fulfill_end(uint256 requestId);

    /**
     * @notice Constructor inherits VRFConsumerBaseV2
     *
     * @param subscriptionId - the subscription ID that this contract uses for funding requests
     * @param vrfCoordinator - coordinator
     * @param keyHash - the gas lane to use, which specifies the maximum gas price to bump to
     */
    constructor(
        address _priceFeedAddress,
        uint256 minimum_Entree_Fee,
        uint64 subscriptionId,
        address vrfCoordinator,
        address link,
        bytes32 keyHash
    ) VRFConsumerBaseV2(vrfCoordinator) payable{
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        ethUsConvert = new EthUsPriceConversion(_priceFeedAddress, minimum_Entree_Fee);
        s_keyHash = keyHash;
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
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
     * @notice Update te gas limit for callback function 
     */
    function updateCallbackGasLimit(uint32 gasLimit) external onlyOwner {
        s_callbackGasLimit = gasLimit;
    }

    /**
     * @notice Get the Random RequestID from Chainlink
     */
    function getRandomRequestID() external view returns (uint256) {
        return s_requestId;
    }

    /**
     * @notice Get the First Random Word Response from Chainlink
     */
    function getFirstRandomWord() external view returns (uint256) {
        return s_randomWords[0];
    }

    /**
     * @notice Get the Second Random Word Response from Chainlink
     */
    function getSecondRandomWord() external view returns (uint256) {
        return s_randomWords[1];
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
        emit ReturnedRandomness1_Funding_begin(s_requestId);
        require(funding_state == FUNDING_STATE.OPEN, "Can't fund yet.  Funding is not opened yet.");
        require(msg.value >= ethUsConvert.getEntranceFee(), "Not enough ETH! Minimum $50 value of ETH require!");
        payers.push(payable(msg.sender));
        emit ReturnedRandomness1_Funding_end(s_requestId);
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
        emit ReturnedRandomness1_endFunding_begin(s_requestId);
        require(funding_state == FUNDING_STATE.OPEN, "Funding is not opened yet.");
        funding_state = FUNDING_STATE.END;
        emit ReturnedRandomness1_endFunding_end(s_requestId);
    }

    /**
     * @notice Owner withdraw the funding.
     */
    function withdraw() external onlyOwner {
        emit ReturnedRandomness2_withdraw_begin(s_requestId);
        require(
            funding_state == FUNDING_STATE.END,
            "Funding must be ended before withdraw!"
        );
        requestRandomWords();
        funding_state = FUNDING_STATE.CLOSED;
        emit ReturnedRandomness2_withdraw_end(s_requestId);
    }

    /**
     * @notice Owner withdraw the funding.
     */
    function withdraw2() external onlyOwner {
        emit ReturnedRandomness2_withdraw_begin(s_requestId);
        require(
            funding_state == FUNDING_STATE.END,
            "Funding must be ended before withdraw!"
        );
        payable(s_owner).transfer(address(this).balance);
        payers = new address payable[](0);
        funding_state = FUNDING_STATE.CLOSED;
        emit ReturnedRandomness2_withdraw_end(s_requestId);
    }

    /**
     * @notice Update the funding state
     */
    function updateFundingState(FUNDING_STATE _funding_state) external onlyOwner {
        funding_state = _funding_state;
    }

    /**
    * @notice Requests randomness
    * Assumes the subscription is funded sufficiently; "Words" refers to unit of data in Computer Science
     */
    function requestRandomWords() internal {
    // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
        s_keyHash,
        s_subscriptionId,
        s_requestConfirmations,
        s_callbackGasLimit,
        s_numWords
        );
    }

    /*
    * @notice Callback function used by VRF Coordinator
    *
    * @param requestId - id of the request
    * @param randomWords - array of random results from VRF Coordinator
    */
    function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
    ) internal override {
        emit ReturnedRandomness3_fulfill_begin(s_requestId);
        s_randomWords = randomWords;

        payable(s_owner).transfer(address(this).balance);
        payers = new address payable[](0);
        funding_state = FUNDING_STATE.CLOSED;
        emit ReturnedRandomness3_fulfill_end(s_requestId);
    }
  }