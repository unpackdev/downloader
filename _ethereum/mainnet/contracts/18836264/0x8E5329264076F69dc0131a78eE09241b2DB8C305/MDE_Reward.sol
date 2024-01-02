// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
//

//RANDOM MDE AIRDROPS TO HOLDERS AT MARKETCAP ACCOMPLISHMENTS  -  DEGEN CONTAGION CONTRACT  -

//Uniswap
import "./IUniswapV2Pair.sol";

//Upkeep
import "./AutomationCompatible.sol";

//VRF 
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./ConfirmedOwner.sol";

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
    
    function getLenghList() external view returns (uint);

    function getAddrById(uint _id) external view returns (address);

    function getIdByIndex(uint _index) external view returns (uint);
}

interface ORACLE {
    function latestAnswer() external view returns (uint256);
}


contract DegenContagionContract is VRFConsumerBaseV2, ConfirmedOwner, AutomationCompatible {
    //Reward 
    IERC20 public MDE;
    IERC20 public USDT;
    IUniswapV2Pair public UNISWAP;
    ORACLE public ORACLECHAINLINK;

    struct Event {
        uint marketCapBorder;
        uint reward;
        uint32 countAdresses; 
        uint[] result;
    }
    mapping(uint => Event) public events;
    uint256 public currentEvent = 1;
    uint public marketCap;
    uint public status;
    address public sc = address(this);
    address public lastSender;
    uint public randomw; 
    
    //VRF
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    
    mapping(uint => uint[2]) private result;
    
    function getResult(uint _id) public view returns ( uint[2] memory ) {
        return result[_id];
    }

    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network
    bytes32 keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 200000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;

constructor(uint64 subscriptionId) VRFConsumerBaseV2(0x271682DEB8C4E0901D1a1550aD2e64D568E69909) ConfirmedOwner(msg.sender) {
        
        COORDINATOR = VRFCoordinatorV2Interface(0x271682DEB8C4E0901D1a1550aD2e64D568E69909);
        s_subscriptionId = subscriptionId;

        uint _decimals = 18;
        // 1 mln.
        events[1].marketCapBorder = 1000000 * 10 ** 6; 
        events[1].reward = 1000 * 10 ** _decimals;
        events[1].countAdresses = 10;

        // 10 mln.
        events[2].marketCapBorder = 10000000 * 10 ** 6; 
        events[2].reward = 1000 * 10 ** _decimals;
        events[2].countAdresses = 10;

        // 69 mln.
        events[3].marketCapBorder = 69000000 * 10 ** 6; 
        events[3].reward = 9000 * 10 ** _decimals;
        events[3].countAdresses = 1;

        // 100 mln. 1 000 MDE
        events[4].marketCapBorder = 100000000 * 10 ** 6; 
        events[4].reward = 1000 * 10 ** _decimals;
        events[4].countAdresses = 10;

        // 100 mln. 10 000 MDE
        events[5].marketCapBorder = 100000000 * 10 ** 6; 
        events[5].reward = 2000 * 10 ** _decimals;
        events[5].countAdresses = 10;

        // 1 billion
        events[6].marketCapBorder = 1000000000 * 10 ** 6; 
        events[6].reward = 1000 * 10 ** _decimals;
        events[6].countAdresses = 10;

        // 100 billion
        events[7].marketCapBorder = 1000000000 * 10 ** 6; 
        events[7].reward = 10000 * 10 ** _decimals;
        events[7].countAdresses = 1;
    }

    function random() public returns (uint256 requestId) {
        numWords = events[currentEvent].countAdresses; 

        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        requestIds.push(requestId);
        lastRequestId = requestId;

        emit RequestSent(requestId, numWords);
        return requestId;
    }

    //Callback from chainlink nodes
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {       
        for (uint8 i; i < _randomWords.length; i++) {
            uint _index = (_randomWords[i] % MDE.getLenghList()) + 1;
            uint _id = MDE.getIdByIndex(_index - 1);
            MDE.transfer(MDE.getAddrById(_id), events[currentEvent].reward);
        }

        currentEvent++;

        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(uint256 _requestId ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    } 

    //Upkeep
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData ) {
        upkeepNeeded = getMarcetCap() > events[currentEvent].marketCapBorder && currentEvent < 8;
    }

    function performUpkeep(bytes calldata performData ) external override {
        if (getMarcetCap() > events[currentEvent].marketCapBorder && currentEvent < 8) {
           random();
        }
    }

    function getMarcetCap() public view returns (uint) { 
        return  ( MDE.totalSupply() / (1 * 10 ** MDE.decimals()) ) * getTokenPrice();
    }

    function getTokenPrice() public view returns(uint) {
        (uint Res0, uint Res1,) = UNISWAP.getReserves();

        //Gets cost 1 ETH in MDE wei
        uint _priceETHMDEwei = (Res1 * 10 ** MDE.decimals()) / Res0; 

        //Integer price, for example 1 ETH = 2357593888390000000000 wei USDT 
        uint256 _priceETHUSDT = ORACLECHAINLINK.latestAnswer() * 10 ** 10; 

        //Gets cost 1 MDE in USDT wei (6 decimals)
        return (_priceETHUSDT * 10 ** MDE.decimals()) / (_priceETHMDEwei / 10 ** 12); 
    }
    
    //ADMIN FUNCTIONS
    function setGasLimit(uint32 _gas) public onlyOwner {
        callbackGasLimit = _gas;
    }

    function setContract(IERC20 _mde, IERC20 _usdt, IUniswapV2Pair _uniswap, ORACLE _chainlink) public onlyOwner {
        MDE = _mde;
        USDT = _usdt;
        UNISWAP = _uniswap;
        ORACLECHAINLINK = _chainlink;
    }
}