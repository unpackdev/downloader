//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/*
This contract allows the sale of an "offering" token in exchange for a "payment"
token.
It let's investors buy tokens at a fixed price but depending on the amount of
interest investors will get a variable allocation size (also called batch auction).
The sale is configured with an target amount of payment token to raise and set
amount of offering tokens to sell. Investors can participate multiple times.
Once the sale ends, investors get to claim their tokens and possibly their
payment token refund (for the execess amount that wasn't used to purchase tokens).
*/

import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IVoters.sol";

contract Sale is ReentrancyGuard {
  using SafeERC20 for IERC20;

  // Information of each user's participation
  struct UserInfo {
      // How many tokens the user has provided
      uint amount;
      // Wether this user has already claimed their refund, defaults to false
      bool claimedRefund;
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
  // Total amount of raising tokens that need to be raised
  uint public raisingAmount;
  // Total amount of offeringToken that will be offered
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
  // Total amount payment token withdrawn by project
  uint public totalAmountWithdrawn;
  // User's participation info
  mapping(address => UserInfo) public userInfo;
  // Participants list
  address[] public addressList;


  event Deposit(address indexed user, uint amount);
  event HarvestRefund(address indexed user, uint amount);
  event HarvestTokens(address indexed user, uint amount);

  constructor(
      IERC20 _paymentToken,
      IERC20 _offeringToken,
      uint _startBlock,
      uint _endBlock,
      uint _tokensBlock,
      uint _offeringAmount,
      uint _raisingAmount,
      uint _perUserCap,
      address _owner,
      address _keeper
  ) {
      paymentToken = _paymentToken;
      offeringToken = _offeringToken;
      startBlock = _startBlock;
      endBlock = _endBlock;
      tokensBlock = _tokensBlock;
      offeringAmount = _offeringAmount;
      raisingAmount = _raisingAmount;
      perUserCap = _perUserCap;
      totalAmount = 0;
      owner = _owner;
      keeper = _keeper;
      _validateBlockParams();
      require(_paymentToken != _offeringToken, 'payment != offering');
      require(_offeringAmount > 0, 'offering > 0');
      require(_raisingAmount > 0, 'raising > 0');
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

  function setRaisingAmount(uint _raisingAmount) public onlyOwnerOrKeeper {
    require (block.number < startBlock, 'sale started');
    raisingAmount = _raisingAmount;
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

    if (votingMinimum > 0) {
      if (votingSnapshotId == 0) {
        require(votingToken.balanceOf(msg.sender) >= votingMinimum, "under minimum locked");
      } else {
        require(votingToken.balanceOfAt(msg.sender, votingSnapshotId) >= votingMinimum, "under minimum locked");
      }
    }

    paymentToken.safeTransferFrom(address(msg.sender), address(this), _amount);
    if (userInfo[msg.sender].amount == 0) {
      addressList.push(address(msg.sender));
    }
    userInfo[msg.sender].amount = userInfo[msg.sender].amount + _amount;
    totalAmount = totalAmount + _amount;
    require(perUserCap == 0 || userInfo[msg.sender].amount <= perUserCap, 'over per user cap');
    emit Deposit(msg.sender, _amount);
  }

  function harvestRefund() public nonReentrant {
    require (block.number > endBlock, 'not harvest time');
    require (userInfo[msg.sender].amount > 0, 'have you participated?');
    require (!userInfo[msg.sender].claimedRefund, 'nothing to harvest');
    uint amount = getRefundingAmount(msg.sender);
    if (amount > 0) {
      paymentToken.safeTransfer(address(msg.sender), amount);
    }
    userInfo[msg.sender].claimedRefund = true;
    emit HarvestRefund(msg.sender, amount);
  }

  function harvestTokens() public nonReentrant {
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

  function harvestAll() public {
    harvestRefund();
    harvestTokens();
  }

  function hasHarvestedRefund(address _user) external view returns (bool) {
      return userInfo[_user].claimedRefund;
  }

  function hasHarvestedTokens(address _user) external view returns (bool) {
      return userInfo[_user].claimedTokens;
  }

  // Allocation in percent, 1 means 0.000001(0.0001%), 1000000 means 1(100%)
  function getUserAllocation(address _user) public view returns (uint) {
    return (userInfo[_user].amount * 1e12) / totalAmount / 1e6;
  }

  // Amount of offering token a user will receive
  function getOfferingAmount(address _user) public view returns (uint) {
    if (totalAmount > raisingAmount) {
      uint allocation = getUserAllocation(_user);
      return (offeringAmount * allocation) / 1e6;
    } else {
      return (userInfo[_user].amount * offeringAmount) / raisingAmount;
    }
  }

  // Amount of the offering token a user will be refunded
  function getRefundingAmount(address _user) public view returns (uint) {
    if (totalAmount <= raisingAmount) {
      return 0;
    }
    uint allocation = getUserAllocation(_user);
    uint payAmount = (raisingAmount * allocation) / 1e6;
    return userInfo[_user].amount - payAmount;
  }

  function getAddressListLength() external view returns (uint) {
    return addressList.length;
  }

  function getParams() external view returns (uint, uint, uint, uint, uint, uint, uint, uint) {
    return (startBlock, endBlock, tokensBlock, offeringAmount, raisingAmount, perUserCap, totalAmount, addressList.length);
  }

  function finalWithdraw(uint _paymentAmount, uint _offeringAmount) public onlyOwner {
    require (_paymentAmount <= paymentToken.balanceOf(address(this)), 'not enough payment token');
    require (_offeringAmount <= offeringToken.balanceOf(address(this)), 'not enough offerring token');
    if (_paymentAmount > 0) {
      paymentToken.safeTransfer(address(msg.sender), _paymentAmount);
      totalAmountWithdrawn += _paymentAmount;
      require(totalAmountWithdrawn <= raisingAmount, 'can only widthdraw what is owed');
    }
    if (_offeringAmount > 0) {
      offeringToken.safeTransfer(address(msg.sender), _offeringAmount);
    }
  }
}
