// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "LinkTokenInterface.sol";
import "VRFCoordinatorV2Interface.sol";
import "VRFConsumerBaseV2.sol";
import "Ownable.sol";
import "EthUsPriceConversion.sol";
import "IEth.sol";

contract MyStorage is IEth, VRFConsumerBaseV2, Ownable {

    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    EthUsPriceConversion internal ethUsConvert;

    // VRF subscription ID.
    uint64 subscriptionId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    bytes32 keyHash;

    // Minimum Entry Fee to fund
   // uint32 minimumEntreeFee;

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

   // address payable[] payers;

  //  enum STATE { OPEN, END, CLOSED }
    STATE internal state;

    // To keep track of the balance of each address
    mapping (address => uint256) internal balanceOfUsers;
    address[] internal senders;
    uint256 totalAmount;

    event fulfill(uint256 requestId);
    event requestWord(uint256 requestId);

    
    /**
     * @notice Constructor inherits VRFConsumerBaseV2
     *
     * @param _subscriptionId - the subscription ID that this contract uses for funding requests
     * @param _vrfCoordinator - coordinator
     * @param _keyHash - the gas lane to use, which specifies the maximum gas price to bump to
     */
    constructor(
        address _owner,
        address _priceFeedAddress,
        uint32 _minimumEntreeFee,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(_vrfCoordinator) payable {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(_link);
        //minimumEntreeFee = _minimumEntreeFee;
        ethUsConvert = new EthUsPriceConversion(_priceFeedAddress, _minimumEntreeFee);
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        s_owner = _owner;
        subscriptionId = _subscriptionId;
        state = STATE.CLOSED;
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
     * @param gasLimit - max gas limit
     */
    function setCallbackGasLimit(uint32 gasLimit) external onlyOwner{
        callbackGasLimit = gasLimit;
    }

    /**
     * @notice Get the Random RequestID from Chainlink
     */
    function getRequestID() external onlyOwner view returns (uint256) {
        return requestId;
    }

    /**
     * @notice Get the First Random Word Response from Chainlink
     */
    function getFirstWord() external onlyOwner view returns (uint256) {
        return randomWords[0];
    }

    /**
     * @notice Get the Second Random Word Response from Chainlink
     */
    function getSecondWord() external onlyOwner view returns (uint256) {
        return randomWords[1];
    }

    /**
     * @notice Open the funding account.  Users can start funding now.
     */
    function start() external onlyOwner {
        require(
            state == STATE.CLOSED,
            "Can't start yet! Current state is not closed yet!"
        );
       state = STATE.OPEN;
    }

    /**
     * @notice It is ended.
     */
    function end() external onlyOwner {
        require(state == STATE.OPEN, "Not opened yet.");
        state = STATE.END;
    }

    /**
     * @notice It is closed.
     */
    function closed() external onlyOwner {
        require(state == STATE.END, "Not ended yet.");
        state = STATE.CLOSED;
    }

     /**
     * @notice Update minimum funding amount
     * @param min_Entree_Fee - minimum amount to send
     */
  /*  function setEntranceFee(uint32 min_Entree_Fee) external onlyOwner {
        minimumEntreeFee = min_Entree_Fee;
    }
    */

    /**
     * @notice Get current funding state.
     */
    function getCurrentState() external onlyOwner view returns (string memory) {
        require((state == STATE.OPEN || state == STATE.END || state == STATE.CLOSED), "unknown state.");
        if (state == STATE.OPEN)
            return "open";
        else if (state == STATE.END)
            return "end";
        else if (state == STATE.CLOSED)
            return "closed";
        else 
            return "unknow state";
    }

     /**
     * @notice Update the funding state
     * @param newState - change the state
     */
    function setState(uint32 newState) external onlyOwner {
        require((newState >= 0 && newState <=2), "Invalid number for state.");
        if (newState == 0)
            state = STATE.OPEN;
        else if(newState == 1)
            state = STATE.END;
        else if(newState == 2)
            state = STATE.CLOSED;
    }

    /**
     * @notice User can enter the fund.  Minimum $50 value of ETH.
     */
    function send(address sender, uint value) external payable onlyOwner {
        // $50 minimum
        require(state == STATE.OPEN, "Can't send yet.");
        //require(value >= minimumEntreeFee, "Not enough ETH! Minimum $50 value of ETH require!");
        require(value >= ethUsConvert.getEntranceFee(), "Not enough ETH! Minimum $50 value of ETH require!");
        // Check for overflows
        require(balanceOfUsers[sender] + value >= balanceOfUsers[sender], "Overflow.");
       // payers.push(payable(sender));
        balanceOfUsers[payable(sender)] += value;
        senders.push(payable(sender));
        totalAmount += value;
    }

   
    /**
     * @notice Get the total amount in this account.
     */
    function getTotalAmount() external onlyOwner view returns (uint256) {
        //return address(s_owner).balance;
        return totalAmount;
    }

    /**
     * @notice Get the balance of the user.
     * @param user - the address of the query balance
     */
    function getUserBalance(address user) external onlyOwner view returns (uint256) {
        return balanceOfUsers[user];
    }

    /**
     * @notice Owner withdraw.
     */
    function wdraw() external onlyOwner {

        require(
            state == STATE.END,
            "Not ended yet!"
        );
        requestRandomWords();
        state = STATE.CLOSED;
    }

    /**
     * Reset the storage.
     */
    function reset() internal {
        for ( uint256 index = 0; 
            index < senders.length;
            index++
        ) {
            address sender = senders[index];
            balanceOfUsers[sender] = 0;
        }
        senders = new address[](0);
    }
    /**
     * @notice Owner withdraw the funding.
     */
    function collect() external onlyOwner {
        //require(address(this).balance > 0, "No transaction. Balance is 0");
        require(totalAmount > 0, "No transaction. Balance is 0");
        payable(s_owner).transfer(totalAmount);
        totalAmount = 0;
        reset();
       // payable(s_owner).transfer(address(this).balance);
       // payers = new address payable[](0);
        state = STATE.CLOSED;
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
        emit requestWord(requestId);
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
        require(address(this).balance > 0, "No transaction. Balance is 0");
        randomWords = _randomWords;   
        payable(s_owner).transfer(totalAmount);
        totalAmount = 0;
        reset();
        state = STATE.CLOSED;
        emit fulfill(requestId);
    }

    /**
     * @notice Transfer to amount to recipient
     * 
     * @param recipient - recipient of the transfer
     * @param amount - amount to transfer
     */
    function transfer(address recipient, uint256 amount) external payable onlyOwner returns (bool success){
        require(recipient != address(0), "Can't transfer to address: 0");
        require(amount > 0, "Transfer amount must be greater than 0.");
        require(totalAmount > amount, "Not enough fund to transfer");
        payable(recipient).transfer(amount);
        balanceOfUsers[recipient] -= amount;
        totalAmount -= amount;
        return true;
    }
 }  
