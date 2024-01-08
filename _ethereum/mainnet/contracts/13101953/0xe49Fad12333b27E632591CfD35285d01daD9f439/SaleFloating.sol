//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/*
This contract allows the sale of an "offering" token in exchange for a "payment"
token.
It let's investors buy tokens at an initial price that increases with every
deposit.
The sale stops once the amount of offered tokens run out or after a specified
block passes.
The speed / curve along which the price increases is specified upfront.
Investors can only participate once and will receive their tokens after the sale
ends (more specifically, after tokensBlock).
*/

import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IVoters.sol";

contract SaleFloating is ReentrancyGuard {
  using SafeERC20 for IERC20;

  // Information of each user's participation
  struct UserInfo {
      // How many tokens the user has provided
      uint amount;
      // What price this user secured
      uint price;
      // Wether this user has already claimed their share of tokens, defaults to false
      bool claimedTokens;
  }

  // Owner address, has access to withdrawing funds after the sale
  address public owner;
  // Keeper address, has access to tweaking sake parameters
  address public keeper;
  // The raising token
  IERC20 public paymentToken;
  // The offering token
  IERC20 public offeringToken;
  // The block number when sale starts
  uint public startBlock;
  // The block number when sale ends
  uint public endBlock;
  // The block number when tokens are redeemable
  uint public tokensBlock;
  // Price to start the sale at (offeringToken per 1e18 of paymentToken)
  uint public startPrice;
  // Rate at which to increase the price (as amount per 1e18 of token invested)
  uint public priceVelocity;
  // Amount of tokens offered for sale
  uint public offeringAmount;
  // Maximum a user can contribute
  uint public perUserCap;
  // Voting token minimum balance to participate
  uint public votingMinimum;
  // Voting token address
  IVoters public votingToken;
  // Voting token snapshot id to use for balances (optional)
  uint public votingSnapshotId;
  // Wether deposits are paused
  bool public paused;
  // Total amount of raising tokens that have already been raised
  uint public totalAmount;
  // Total amount of offering tokens sold
  uint public totalOfferingAmount;
  // User's participation info
  mapping(address => UserInfo) public userInfo;
  // Participants list
  address[] public addressList;


  event Deposit(address indexed user, uint amount, uint price);
  event HarvestTokens(address indexed user, uint amount);

  constructor(
      IERC20 _paymentToken,
      IERC20 _offeringToken,
      uint _startBlock,
      uint _endBlock,
      uint _tokensBlock,
      uint _startPrice,
      uint _priceVelocity,
      uint _offeringAmount,
      uint _perUserCap,
      address _owner,
      address _keeper
  ) {
      paymentToken = _paymentToken;
      offeringToken = _offeringToken;
      startBlock = _startBlock;
      endBlock = _endBlock;
      tokensBlock = _tokensBlock;
      startPrice = _startPrice;
      priceVelocity = _priceVelocity;
      offeringAmount = _offeringAmount;
      perUserCap = _perUserCap;
      owner = _owner;
      keeper = _keeper;
      _validateBlockParams();
      require(_paymentToken != _offeringToken, 'payment != offering');
      require(_priceVelocity > 0, 'price velocity > 0');
      require(_offeringAmount > 0, 'offering amount > 0');
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "!owner");
    _;
  }

  modifier onlyOwnerOrKeeper() {
    require(msg.sender == owner || msg.sender == keeper, "!owner or keeper");
    _;
  }

  function _validateBlockParams() private view {
    require(startBlock > block.number, 'start > now');
    require(endBlock >= startBlock, 'end > start');
    require(endBlock - startBlock <= 172800, 'end < 1 month after start');
    require(tokensBlock - endBlock <= 172800, 'tokens < 1 month after end');
  }

  function setOfferingAmount(uint _offerAmount) public onlyOwnerOrKeeper {
    require (block.number < startBlock, 'sale started');
    offeringAmount = _offerAmount;
  }

  function setStartPrice(uint _startPrice) public onlyOwnerOrKeeper {
    require (block.number < startBlock, 'sale started');
    startPrice = _startPrice;
  }

  function setPriceVelocity(uint _priceVelocity) public onlyOwnerOrKeeper {
    require (block.number < startBlock, 'sale started');
    priceVelocity = _priceVelocity;
  }

  function setStartBlock(uint _block) public onlyOwnerOrKeeper {
    startBlock = _block;
    _validateBlockParams();
  }

  function setEndBlock(uint _block) public onlyOwnerOrKeeper {
    endBlock = _block;
    _validateBlockParams();
  }

  function setTokensBlock(uint _block) public onlyOwnerOrKeeper {
    tokensBlock = _block;
    _validateBlockParams();
  }

  function configureVotingToken(uint minimum, address token, uint snapshotId) public onlyOwnerOrKeeper {
    votingMinimum = minimum;
    votingToken = IVoters(token);
    votingSnapshotId = snapshotId;
  }

  function togglePaused() public onlyOwnerOrKeeper {
    paused = !paused;
  }

  function deposit(uint _amount) public {
    require(!paused, 'paused');
    require(block.number > startBlock && block.number < endBlock, 'sale not active');
    require(_amount > 0, 'need amount > 0');
    require(perUserCap == 0 || _amount <= perUserCap, 'over per user cap');
    require(userInfo[msg.sender].amount == 0, 'already participated');
    require(totalOfferingAmount <= offeringAmount, 'sold out');

    if (votingMinimum > 0) {
      if (votingSnapshotId == 0) {
        require(votingToken.balanceOf(msg.sender) >= votingMinimum, "under minimum locked");
      } else {
        require(votingToken.balanceOfAt(msg.sender, votingSnapshotId) >= votingMinimum, "under minimum locked");
      }
    }

    paymentToken.safeTransferFrom(address(msg.sender), address(this), _amount);
    addressList.push(address(msg.sender));
    userInfo[msg.sender].amount = _amount;
    totalAmount += _amount;
    uint price = startPrice + ((totalAmount * priceVelocity) / 1e18);
    userInfo[msg.sender].price = price;
    totalOfferingAmount += getOfferingAmount(msg.sender);
    emit Deposit(msg.sender, _amount, price);
  }

  function harvestTokens() public nonReentrant {
    require(!paused, 'paused');
    require (block.number > tokensBlock, 'not harvest time');
    require (userInfo[msg.sender].amount > 0, 'have you participated?');
    require (!userInfo[msg.sender].claimedTokens, 'nothing to harvest');
    uint amount = getOfferingAmount(msg.sender);
    if (amount > 0) {
      offeringToken.safeTransfer(address(msg.sender), amount);
    }
    userInfo[msg.sender].claimedTokens = true;
    emit HarvestTokens(msg.sender, amount);
  }

  function hasHarvestedTokens(address _user) external view returns (bool) {
      return userInfo[_user].claimedTokens;
  }

  // Amount of offering token a user will receive
  function getOfferingAmount(address _user) public view returns (uint) {
      return (userInfo[_user].amount * 1e18) / userInfo[_user].price;
  }

  function getAddressListLength() external view returns (uint) {
      return addressList.length;
  }

  function getParams() external view returns (uint, uint, uint, uint, uint, uint, uint, uint, uint) {
    return (startBlock, endBlock, tokensBlock, startPrice, priceVelocity, offeringAmount, perUserCap, totalAmount, totalOfferingAmount);
  }

  function finalWithdraw(uint _paymentAmount, uint _offeringAmount) public onlyOwner {
    require (_paymentAmount <= paymentToken.balanceOf(address(this)), 'not enough payment token');
    require (_offeringAmount <= offeringToken.balanceOf(address(this)), 'not enough offerring token');
    if (_paymentAmount > 0) {
      paymentToken.safeTransfer(address(msg.sender), _paymentAmount);
    }
    if (_offeringAmount > 0) {
      offeringToken.safeTransfer(address(msg.sender), _offeringAmount);
    }
  }
}
