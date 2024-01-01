// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function allowance(
    address owner,
    address spender
  ) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface AggregatorV3Interface {
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract BlockStar_Presale {
  IERC20 public Token;
  IERC20 public USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  AggregatorV3Interface public priceFeed;

  address payable public owner;

  uint256 public tokenPerUsd = 33 ether;
  uint256 public totalUsers;
  uint256 public soldToken;
  uint256 public totalSupply = 1500_000_000 ether;
  uint256 public minimumBuyInUsdt = 1 * 1e6;
  uint256 public minimumBuyInEth = 0.00054 ether;
  uint256 public maximumBuy = 3000000 ether;
  uint256 public amountRaisedETHUSDT;
  uint256 public amountRaisedUSDT;

  bool public presaleStatus;
  bool public enableClaim;

  uint256 public constant divider = 100;

  // Define the vesting period (in seconds) for 70% of the tokens (12 weeks)
  uint256 public vestingStartTime;
  uint256 public vestingDuration = 90 days;

  struct User {
    uint256 eth_usdt_balance;
    uint256 usdt_balance;
    uint256 token_balance;
    uint256 claimable_amount;
    uint256 vesting_amount;
    uint256 claimed_token;
  }

  mapping(address => User) public users;

  event BuyToken(address indexed user, uint256 amount);
  event ClaimToken(address indexed user, uint256 amount);
  event UpdatePrice(uint256 oldPrice, uint256 newPrice);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  modifier onlyOwner() {
    require(msg.sender == owner, "Presale: Not an owner");
    _;
  }

  constructor(address _tokenAddress) {
    Token = IERC20(_tokenAddress);
    owner = payable(msg.sender);
    priceFeed = AggregatorV3Interface(
      0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    );
    presaleStatus = true;
  }

  receive() external payable {}

  function getLatestPrice() public view returns (uint256) {
    (, int256 price, , , ) = priceFeed.latestRoundData();
    return uint256(price);
  }

  function buyToken() public payable {
    require(presaleStatus, "Presale: Presale is finished");
    require(
      msg.value >= minimumBuyInEth,
      "Presale: Amount should be greater than minimum buy"
    );
    require(soldToken <= totalSupply, "Presale: All tokens sold");

    uint256 totalTokens = nativeToToken(msg.value);

    // Calculate the amount to vest (70%)
    uint256 vestingAmount = (totalTokens * 70) / 100;
    uint256 nonVestingAmount = (totalTokens * 30) / 100;

    // Update the soldToken, amountRaisedETHUSDT, and user balances
    soldToken += totalTokens;
    amountRaisedETHUSDT += (msg.value * getLatestPrice()) / (1 ether);

    users[msg.sender].eth_usdt_balance +=
      (msg.value * getLatestPrice()) /
      (1 ether);

    users[msg.sender].token_balance += totalTokens;
    users[msg.sender].claimable_amount += nonVestingAmount;
    users[msg.sender].vesting_amount += vestingAmount;

    require(
      users[msg.sender].token_balance <= maximumBuy,
      "Presale: Maximum buy limit reached"
    );

    emit BuyToken(msg.sender, totalTokens);
  }

  function buyTokenUSDT(uint256 amount) external {
    require(presaleStatus == true, "Presale : Presale is finished");
    require(
      amount >= minimumBuyInUsdt,
      "amount should be greater than minimum buy"
    );
    require(soldToken <= totalSupply, "All Sold");

    USDT.transferFrom(msg.sender, owner, amount);

    uint256 totalTokens = usdtToToken(amount);

    // Calculate the amount to vest (70%)
    uint256 vestingAmount = (totalTokens * 70) / 100;
    uint256 nonVestingAmount = (totalTokens * 30) / 100;

    // Update soldToken and amountRaisedUSDT
    soldToken = soldToken + (totalTokens);
    amountRaisedUSDT = amountRaisedUSDT + (amount);

    // Update user balances
    users[msg.sender].usdt_balance += amount;
    users[msg.sender].token_balance += totalTokens;
    users[msg.sender].claimable_amount += nonVestingAmount;
    users[msg.sender].vesting_amount += vestingAmount;

    require(
      users[msg.sender].token_balance <= maximumBuy,
      "Presale: Maximum buy limit reached"
    );
  }

  function endPresale() external onlyOwner {
    require(presaleStatus, "Presale: Presale is not active");
    presaleStatus = false;
    vestingStartTime = block.timestamp;
  }

  // Existing buyToken and buyTokenUSDT functions...
  function claimTokens() external {
    require(enableClaim, "Presale: Claim not active yet");
    require(vestingStartTime > 0, "Presale: Vesting not started");

    (uint256 claimableAmount, bool isVestingUnlock) = getClaimableTokens(
      msg.sender
    );

    require(claimableAmount > 0, "Presale: No tokens to claim");

    users[msg.sender].claimed_token += claimableAmount;
    users[msg.sender].token_balance -= claimableAmount;

    if (isVestingUnlock) {
      users[msg.sender].claimable_amount = 0;
      users[msg.sender].vesting_amount = 0;
    } else {
      users[msg.sender].claimable_amount = 0;
    }

    Token.transfer(msg.sender, claimableAmount);

    emit ClaimToken(msg.sender, claimableAmount);
  }

  function enableTokenClaim(bool _state) external onlyOwner {
    enableClaim = _state;
  }

  function stopPresale(bool _off) external onlyOwner {
    presaleStatus = _off;
  }

  function setMinimumBuyInUsdt(uint256 _minimumBuyInUsdt) external onlyOwner {
    minimumBuyInUsdt = _minimumBuyInUsdt;
  }

  function setMinimumBuyInEth(uint256 _minimumBuyInEth) external onlyOwner {
    minimumBuyInEth = _minimumBuyInEth;
  }

  function setMaxTokenBuy(uint256 _maxTokens) external onlyOwner {
    maximumBuy = _maxTokens;
  }

  function nativeToToken(uint256 _amount) public view returns (uint256) {
    uint256 ethToUsd = (_amount * getLatestPrice()) / (1 ether);
    uint256 numberOfTokens = (ethToUsd * tokenPerUsd) / (1e8);
    return numberOfTokens;
  }

  function usdtToToken(uint256 _amount) public view returns (uint256) {
    uint256 numberOfTokens = (_amount * tokenPerUsd) / (1e6);
    return numberOfTokens;
  }

  function changePrice(uint256 _price) external onlyOwner {
    tokenPerUsd = _price;
  }

  function transferOwnership(address payable _newOwner) external onlyOwner {
    require(_newOwner != address(0), "Ownable: new owner is the zero address");
    address payable oldOwner = owner;
    owner = _newOwner;
    emit OwnershipTransferred(oldOwner, owner);
  }

  function changeToken(address _token) external onlyOwner {
    Token = IERC20(_token);
  }

  function changeUSDT(address _USDT) external onlyOwner {
    USDT = IERC20(_USDT);
  }

  function transferFunds(uint256 _value) external onlyOwner {
    owner.transfer(_value);
  }

  function transferTokens(IERC20 token, uint256 _value) external onlyOwner {
    token.transfer(msg.sender, _value);
  }

  function getClaimableTokens(
    address _user
  ) public view returns (uint256, bool) {
    uint256 claimableAmount = users[_user].claimable_amount;
    bool isVestingUnlock = block.timestamp >=
      vestingStartTime + vestingDuration;

    if (isVestingUnlock) {
      claimableAmount += users[_user].vesting_amount;
    }

    return (claimableAmount, isVestingUnlock);
  }
}