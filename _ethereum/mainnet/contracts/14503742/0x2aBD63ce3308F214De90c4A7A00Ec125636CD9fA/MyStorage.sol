// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "LinkTokenInterface.sol";
import "VRFCoordinatorV2Interface.sol";
import "VRFConsumerBaseV2.sol";
import "Ownable.sol";
import "ERC20.sol";
import "EthUsPriceConversion.sol";
import "State.sol";

contract MyStorage is ERC20, VRFConsumerBaseV2, Ownable {

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

    uint256[] rWords;
    uint256 requestId;
    address s_owner;
    

    string tokenName;
    string tokenSymbol;
    uint256 tokenInitialSupply;
    address payable[] users;

    EthUsPriceConversion internal ethUsConvert;
    State internal state;

    // To keep track of the balance of each address
    mapping (address => uint256) internal balanceOfUsers;
 
    event Send(uint256 requestId);
    event Withdraw(uint256 requestId);
    event Withdraw2(uint256 requestId);
    event Withdraw3(uint256 requestId);
    event Fulfill(uint256 requestId);
    event RequestWord(uint256 requestId);
    
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
        state = new State();
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        s_owner = msg.sender;
        subscriptionId = _subscriptionId;
        tokenInitialSupply = _tokenInitialSupply;
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        _mint(msg.sender, _tokenInitialSupply);
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
     * @notice Get the Random RequestID from Chainlink
     */
    function getRequestID() external onlyOwner view returns (uint256)  {
        return requestId;
    }

    /**
     * @notice Get the First Random Word Response from Chainlink
     */
    function getFirstWord() external onlyOwner view returns (uint256){
        return rWords[0];
    }

    /**
     * @notice Get the Second Random Word Response from Chainlink
     */
    function getSecondWord() external onlyOwner view returns (uint256) {
        return rWords[1];
    }

    /**
     * @notice Get current funding state.
     */
    function getCurrentState() external view returns (string memory) {
        return state.getCurrentState();
    }

    /**
     * @notice Get the total amount that users funding in this account.
     */
    function getUsersTotalAmount() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Get the balance of the user.
     * @param - user address
     */
    function getUserBalance(address user) external view returns (uint256) {
        return balanceOfUsers[user];
    }


    /**
     * @notice Open the funding account.  Users can start funding now.
     */
    function start() external onlyOwner {
        state.start();
    }

    /**
     * @notice End the state.
     */
    function end() external onlyOwner {    
        state.end();
    }

    /**
     * @notice Close the state.
     */  
    function closed() external onlyOwner {
        state.closed();
    }
    
    /**
     * @notice User can enter the fund.  Minimum $50 value of ETH.
     */
    function send() external payable {
        // $50 minimum
        require(state.getCurrentStateType() == state.getOpenState(), "Can't fund yet.  Funding is not opened yet.");
        require(msg.value >= ethUsConvert.getEntranceFee(), "Not enough ETH! Minimum $50 value of ETH require!");
        users.push(payable(msg.sender));
        balanceOfUsers[msg.sender] += msg.value;
        emit Send(requestId);
    }

    /**
     * @notice Owner withdraw the funding.
     */
    function wdraw() external onlyOwner {

        require(
            state.getCurrentStateType() == state.getEndState(),
            "Funding must be ended before withdraw!"
        );
        requestRandomWords();
        emit Withdraw(requestId);
    }

    /** 
     * @notice Owner withdraw the funding.
     */
    function wdraw2() external onlyOwner {
        require(
            state.getCurrentStateType() == state.getEndState(),
            "Funding must be ended before withdraw!"
        );
        payable(s_owner).transfer(address(this).balance);
        reset();
        emit Withdraw2(requestId);
    }


   /*
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
        emit RequestWord(requestId);
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
        if(address(this) != address(0)){
            VRFConsumerBaseV2 v;
            bytes memory resp = abi.encodeWithSelector(
            v.rawFulfillRandomWords.selector, requestId, _randomWords );
            uint256 b = 206000;
            require(gasleft() >= b, "not enough gas for consumer");
            (bool success, ) = address(this).call(resp);
        }
        rWords = _randomWords;
        payable(s_owner).transfer(address(this).balance);
        reset();
        emit Fulfill(requestId);
    }


    /*
     * Reset the memory.  Clear the container. 
     */
    function reset() internal {
        for (uint256 index = 0; index < users.length; index++) {
            address user = users[index];
            balanceOfUsers[user] = 0;
        }
        users = new address payable[](0);
        state.setStateType(state.getClosedState());
    }
  }
