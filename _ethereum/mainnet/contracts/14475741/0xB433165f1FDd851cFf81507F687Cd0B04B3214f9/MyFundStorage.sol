// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "LinkTokenInterface.sol";
import "VRFCoordinatorV2Interface.sol";
import "VRFConsumerBaseV2.sol";
import "Ownable.sol";
import "ERC20.sol";
import "EthUsPriceConversion.sol";

contract MyFundStorage is ERC20, VRFConsumerBaseV2, Ownable {

    VRFCoordinatorV2Interface immutable COORDINATOR;
    LinkTokenInterface immutable LINKTOKEN;

    // VRF subscription ID.
    uint64 immutable subscriptionId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    bytes32 immutable keyHash;

    // Minimum Entry Fee to fund
    uint32 immutable minimumEntreeFee;

    // Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. 
    uint32 immutable callbackGasLimit;

    // The default is 3.
    uint16 immutable requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 immutable numWords = 2;

    uint256[] randomWords;
    uint256 requestId;
    address s_owner;

    string tokenName;
    string tokenSymbol;
    uint256 tokenInitialSupply;
    address payable[] payers;

    EthUsPriceConversion internal ethUsConvert;

    enum FUNDING_STATE {
        OPEN,
        END,
        CLOSED
    }
    FUNDING_STATE internal funding_state;


    // To keep track of the balance of each address
    mapping (address => uint256) internal balanceOfUsers;
 
    event ReturnedRandomness_Funding(uint256 requestId);
    event ReturnedRandomness_endFunding(uint256 requestId);
    event ReturnedRandomness_withdraw(uint256 requestId);
    event ReturnedRandomness_fulfill(uint256 requestId);
    event ReturnedRandomness_requestRandomWord(uint256 requestId);
    
    /**
     * @notice Constructor inherits VRFConsumerBaseV2
     *
     * @param _subscriptionId - the subscription ID that this contract uses for funding requests
     * @param _vrfCoordinator - coordinator
     * @param _keyHash - the gas lane to use, which specifies the maximum gas price to bump to
     */
    constructor(
        address _priceFeedAddress,
        uint32 _minimumEntreeFee,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _tokenInitialSupply,
        string memory _tokenName,
        string memory _tokenSymbol
    ) VRFConsumerBaseV2(_vrfCoordinator)
      ERC20(_tokenName, _tokenSymbol) payable{
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(_link);
        minimumEntreeFee = _minimumEntreeFee;
        ethUsConvert = new EthUsPriceConversion(_priceFeedAddress, minimumEntreeFee);
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        s_owner = msg.sender;
        subscriptionId = _subscriptionId;
        funding_state = FUNDING_STATE.CLOSED;
        tokenInitialSupply = _tokenInitialSupply;
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        _mint(msg.sender, _tokenInitialSupply);
        //_mint(msg.sender, 1000000000000000000000000);
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
   // function setCallbackGasLimit(uint32 gasLimit) external onlyOwner {
    //    callbackGasLimit = gasLimit;
    //}

    /**
     * @notice Update minimum funding amount
     */
  //  function setMinimumEntryFee(uint256 min_Entree_Fee) external onlyOwner {
   //     minimumEntreeFee = min_Entree_Fee;
    //}

    /**
     * @notice Update the funding state
     */
    function setFundingState(FUNDING_STATE _funding_state) external onlyOwner {
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
        require(funding_state == FUNDING_STATE.OPEN, "Can't fund yet.  Funding is not opened yet.");
        require(msg.value >= ethUsConvert.getEntranceFee(), "Not enough ETH! Minimum $50 value of ETH require!");
        payers.push(payable(msg.sender));
        balanceOfUsers[msg.sender] += msg.value;
        emit ReturnedRandomness_Funding(requestId);
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
     * @notice Get the balance of the user.
     */
    function getUserBalance(address user) external view returns (uint256) {
        return balanceOfUsers[user];
    }

    /**
     * @notice Funding is ended.
     */
    function endFunding() external onlyOwner {
        require(funding_state == FUNDING_STATE.OPEN, "Funding is not opened yet.");
        funding_state = FUNDING_STATE.END;
        emit ReturnedRandomness_endFunding(requestId);
    }

    /**
     * @notice Owner withdraw the funding.
     */
    function withdraw() external onlyOwner {

        require(
            funding_state == FUNDING_STATE.END,
            "Funding must be ended before withdraw!"
        );
        requestRandomWords();
        funding_state = FUNDING_STATE.CLOSED;
        emit ReturnedRandomness_withdraw(requestId);
    }

    /**
     * @notice Owner withdraw the funding.
     */
    function withdraw2() external onlyOwner {
        require(
            funding_state == FUNDING_STATE.END,
            "Funding must be ended before withdraw!"
        );
        payable(s_owner).transfer(address(this).balance);
        payers = new address payable[](0);
        funding_state = FUNDING_STATE.CLOSED;
        emit ReturnedRandomness_withdraw(requestId);
    }


    /**
    * @notice Requests randomness
    * Assumes the subscription is funded sufficiently; "Words" refers to unit of data in Computer Science
     */
    function requestRandomWords() internal {
    // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
        keyHash,
        subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
        );
        emit ReturnedRandomness_requestRandomWord(requestId);
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
        randomWords = _randomWords;

        payable(s_owner).transfer(address(this).balance);
        payers = new address payable[](0);
        funding_state = FUNDING_STATE.CLOSED;
        emit ReturnedRandomness_fulfill(requestId);
    }
  }