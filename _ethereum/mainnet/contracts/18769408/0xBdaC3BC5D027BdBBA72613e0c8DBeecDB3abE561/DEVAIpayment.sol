// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient,uint256 amount) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract DEVAIpayment {
  address public tokenAddress = 0xF7498c98789957F4eE53B3E37fF5B7Ef8A6CFC7b;
  IERC20 token =  IERC20(tokenAddress);

  address public receiverAddress = 0x7c475de1B63D37D7D5eaB1B6e7ea4f7536409699;
  
  address public owner;

  struct order{
    uint256 sequenceNumber;
    uint256 orderId;
    uint256 tokensAmount;
    uint256 conversionRate; //token to ETH conversion rate at the time of payment
    address userAddress;
    uint256 createdTime;
  }

  order[] public orders;
  uint256 public totalTokensPaid;
  uint256 orderSequenceNumber;

  mapping (address => uint256) public totalTokensPaidByUser;
  mapping (address => order[]) public userOrders;
  mapping (uint256 => order) public orderByOrderId;
  mapping (uint256 => order) public orderBySequenceNumber;

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  event paidByToken(address indexed _from, uint256 indexed _order_id, uint256 _tokenAmount, uint256 _ETHconversionRate );

  constructor() {
    owner = msg.sender;
  }

  function payByToken(uint256 _tokenAmount, uint256 _orderId, uint256 _conversionRate) public returns(bool){
 
    uint256 allownace = token.allowance(msg.sender,address(this));
    require( allownace >= _tokenAmount, "Not enough allownace to transfer the tokens");
    require( token.balanceOf(msg.sender) >= _tokenAmount, "Not enough balance to transfer the tokens");
    token.transferFrom(msg.sender, receiverAddress,_tokenAmount);
   
    totalTokensPaidByUser[msg.sender] += _tokenAmount;

     order memory newOrder = order(
            orderSequenceNumber,
            _orderId,
            _tokenAmount,
            _conversionRate,
            msg.sender,
            block.timestamp
        );
    
    userOrders[msg.sender].push(newOrder);
    orderByOrderId[_orderId] = newOrder;
    orderBySequenceNumber[orderSequenceNumber] = newOrder;
    orders.push(newOrder);
    orderSequenceNumber++;
    
    emit paidByToken(msg.sender, _orderId, _tokenAmount, _conversionRate);

    return true;
  }
  
  function getOrderDetailsByOrderId(uint256 _orderId) public view returns(order memory){
    return orderByOrderId[_orderId];
  }
  
  function getOrderDetailsByOrderSequenceNumber(uint256 _orderSequenceNumber) public view returns(order memory){
    return orderBySequenceNumber[_orderSequenceNumber];
  }

  function getAllOrders() public view returns(order[] memory){
    return orders;
  }

  function getOrdersByWalletAddress(address _wallet) public view returns(order[] memory){
    return userOrders[_wallet];
  }
  
  function setReceiverAddress(address _newReceiverAddress) public onlyOwner{
    receiverAddress = _newReceiverAddress;
  }

  function rescueTokens(address _tokenAddress) public onlyOwner{
    IERC20 rescueToken =  IERC20(_tokenAddress);
    rescueToken.transfer(receiverAddress, rescueToken.balanceOf(address(this)));
  }

  function transferOwnership(address _newOwner) public onlyOwner{
    owner = _newOwner;
  }
}