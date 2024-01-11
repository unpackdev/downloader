// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

// OpenZeppelin
import "./IERC20.sol";
import "./Ownable.sol";

contract Bridge is Ownable {

    struct BridgeRequest {
        address account;
        uint256 amount;
        uint256 blockNumber;
        uint256 timestamp;
    }

    event RequestSent (uint256 _id, address indexed _account, uint256 _amount, uint256 _blocknumber);
    event RequestReceived (uint256 _id, address indexed _account, uint256 _amount, uint256 _blocknumber);

    constructor() {
        outgoingTransferFee = 0.1 * 10**18;
        settlingAgent = payable(msg.sender);
    }

    uint256 public depositedTokens;

    address payable public settlingAgent;
    function setSettlingAgent(address _address) public onlyOwner {
        settlingAgent = payable(_address);
    }

    address public tokenAddress;
    function setTokenAddress(address _address) public onlyOwner {
        tokenAddress = payable(_address);
    }

    uint256 public outgoingTransferFee;
    function setOutgoingTransferFee(uint256 _amount) public onlyOwner {
        outgoingTransferFee = _amount;
    }

    modifier onlyAgent() {
        require(msg.sender == settlingAgent, "This action can only be executed by the settling agent");
        _;
    }

    uint256 public sentRequestCount;
    mapping (uint256 => BridgeRequest) public sentRequests;

    uint256 public receivedRequestCount;
    mapping (uint256 => bool) public receivedRequests;

    function depositTokens(uint256 _amount) public onlyOwner {
        require(_amount > 0, "Amount must be larger than zero");

        IERC20 erc20 = IERC20(tokenAddress) ;
        erc20.transferFrom (msg.sender, address(this) , _amount);
        depositedTokens += _amount;
    }

    function withdrawETH() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    function withdrawToken(address _tokenAddress) public onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    function bridgeToken(uint256 _amount) public payable  {
        require(msg.value >= outgoingTransferFee, "Underpaid transaction: please provide the outgoing transfer fee." );

        sentRequestCount++;
        IERC20 erc20 = IERC20(tokenAddress);

        uint256 balanceBefore = erc20.balanceOf(address(this));
        erc20.transferFrom (msg.sender, address(this) , _amount);

        uint256 balanceExpected = balanceBefore + _amount;
        require(erc20.balanceOf(address(this)) >= balanceExpected, "Did not receive enough tokens from sender. Is the bridge exempted from taxes?");

        settlingAgent.transfer(msg.value);

        depositedTokens += _amount;
        sentRequests[sentRequestCount].account =  msg.sender;
        sentRequests[sentRequestCount].amount = _amount;
        sentRequests[sentRequestCount].blockNumber = block.number;
        sentRequests[sentRequestCount].timestamp = block.timestamp;

        emit RequestSent(sentRequestCount, msg.sender, _amount, block.number);
    }
    function settleRequest(uint256 _id, address _account, uint256 _amount) public onlyAgent {
        require (!receivedRequests[_id], "This request was already settled");
        require (depositedTokens >= _amount, "Token deposit insufficient for settlement");

        receivedRequestCount++;
        receivedRequests[receivedRequestCount] = true;

        IERC20 erc20 = IERC20(tokenAddress);
        erc20.transfer(_account, _amount);

        depositedTokens -= _amount;
        emit RequestReceived(receivedRequestCount, _account, _amount, block.number);
    }

    receive() external payable {}
    fallback() external payable {}
}
