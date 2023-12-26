// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient,uint256 amount) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
}

contract DevAIrevenueSplit {
  address public tokenAddress = 0xF7498c98789957F4eE53B3E37fF5B7Ef8A6CFC7b;
  IERC20 token =  IERC20(tokenAddress);
  
  address public owner;
 
  mapping (address => uint256) public lastClaimed;

  uint256 public minHoldingPercentage = 50; //0.5%
  uint256 public revenueSplitPerToken = 307750701415;
  uint256 public distributionTime = block.timestamp;
  uint256 public totalClaimed;

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function claim() public {
    require(isClaimable(msg.sender) == true,"Not eligible to claim");
    uint256 revenueShare = (((token.balanceOf(msg.sender) * revenueSplitPerToken))/(10**token.decimals()));
    require(address(this).balance >= revenueShare,"Insufficient contract balance");
    lastClaimed[msg.sender] = block.timestamp;
    payable(msg.sender).transfer(revenueShare);
    totalClaimed += revenueShare;
  }

  function isClaimable(address _wallet) public view returns(bool) {
    uint256 holdingPercentage = (((token.balanceOf(_wallet) * 10000)/token.totalSupply()));
    if(lastClaimed[_wallet] < distributionTime && holdingPercentage >= minHoldingPercentage){
      return true;
    }else {
      return false;
    }
  }

  function getSplitShare(address _wallet) public view returns(uint256, uint256){
    uint256 _tokenBalance = token.balanceOf(_wallet);
    uint256 percentShare = (((_tokenBalance * 10000)/token.totalSupply()));
    uint256 revenueShare = (((_tokenBalance * revenueSplitPerToken))/(10**token.decimals()));

    if(isClaimable(_wallet) == false){
      return (percentShare,0);
    } else {
      return(percentShare,revenueShare);
    }
  }

  constructor() {
    owner = msg.sender;
  }
  
  function distributeRevenue(uint256 _revenueSplitPerToken) public onlyOwner{
    distributionTime = block.timestamp;
    revenueSplitPerToken = _revenueSplitPerToken;
  }

  function setRevenueSplitPerToken(uint256 _revenueSplitPerToken) public onlyOwner{
    revenueSplitPerToken = _revenueSplitPerToken;
  }

  function setMinHoldingPercentage(uint256 _newMinHoldingPercentage) public onlyOwner {
    require(_newMinHoldingPercentage > 0, "Percentage must be greater than zero");
    minHoldingPercentage = _newMinHoldingPercentage;
  }

  function setUserClaimTime(address _wallet, uint256 _timestamp) public onlyOwner{ // Testing function
    lastClaimed[_wallet] = _timestamp;
  }

  function setTokenAddress(address _newTokenAddress) public onlyOwner{
    tokenAddress = _newTokenAddress;
  }

  function transferOwnership(address _newOwner) public onlyOwner{
    owner = _newOwner;
  }

  function withdraw() public onlyOwner{
    payable(msg.sender).transfer(address(this).balance);
  }

  receive() external payable {}
}