//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IVoters.sol";
import "./IERC677Receiver.sol";

contract SaleDutch is ReentrancyGuard, IERC677Receiver {
    using SafeERC20 for IERC20;

    // Information of each user's participation
    struct UserInfo {
        // How many tokens the user has provided
        uint amount;
        // Wether this user has already claimed their share of tokens, defaults to false
        bool claimedTokens;
    }

    // Owner address, has access to withdrawing funds after the sale
    address public owner;
    // The raising token
    IERC20 public paymentToken;
    // The offering token
    IERC20 public offeringToken;
    // The time (unix seconds) when sale starts
    uint public startTime;
    // The time (unix security) when sale ends
    uint public endTime;
    // Price to start the sale at (offeringToken per 1e18 of paymentToken)
    uint public startPrice;
    // Reserve price (as amount per 1e18 of token invested)
    uint public endPrice;
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
    // Wether the sale is finalized
    bool public finalized;
    // Total amount of raising tokens that have already been raised
    uint public totalAmount;
    // User's participation info
    mapping(address => UserInfo) public userInfo;
    // Participants list
    address[] public addressList;


    event Deposit(address indexed user, uint amount);
    event HarvestTokens(address indexed user, uint amount);
    event HarvestRefund(address indexed user, uint amount);

    constructor(
        address _paymentToken,
        address _offeringToken,
        uint _startTime,
        uint _endTime,
        uint _startPrice,
        uint _endPrice,
        uint _offeringAmount,
        uint _perUserCap,
        address _owner
    ) {
        paymentToken = IERC20(_paymentToken);
        offeringToken = IERC20(_offeringToken);
        startTime = _startTime;
        endTime = _endTime;
        startPrice = _startPrice;
        endPrice = _endPrice;
        offeringAmount = _offeringAmount;
        perUserCap = _perUserCap;
        owner = _owner;
        require(_paymentToken != _offeringToken, 'payment != offering');
        require(startTime > block.timestamp, 'start > now');
        require(startTime < endTime, 'start < end');
        require(startTime < 10000000000, 'start time not unix');
        require(endTime < 10000000000, 'start time not unix');
        require(_startPrice > 0, 'start price > 0');
        require(_offeringAmount > 0, 'offering amount > 0');
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

    function togglePaused() public onlyOwner {
        paused = !paused;
    }

    function finalize() public {
        require(msg.sender == owner || block.timestamp > endTime + 7 days, 'no allowed');
        finalized = true;
    }

    function getAddressListLength() external view returns (uint) {
        return addressList.length;
    }

    function getParams() external view returns (uint, uint, uint, uint, uint, uint, uint, uint, uint, bool, bool) {
        return (startTime, endTime, startPrice, endPrice,
                offeringAmount, perUserCap, totalAmount, currentPrice(), clearingPrice(), paused, finalized);
    }

    function priceChange() public view returns (uint) {
        return (startPrice - endPrice) / (endTime - startTime);
    }

    function currentPrice() public view returns (uint) {
        if (block.timestamp <= startTime) return startPrice;
        if (block.timestamp >= endTime) return endPrice;
        return startPrice - ((block.timestamp - startTime) * priceChange());
    }

    function tokenPrice() public view returns (uint) {
        return (totalAmount * 1e18) / offeringAmount;
    }

    function clearingPrice() public view returns (uint) {
        if (tokenPrice() > currentPrice()) return tokenPrice();
        return currentPrice();
    }

    function saleSuccessful() public view returns (bool) {
        return tokenPrice() >= clearingPrice();
    }

    function commitmentSize(uint amount) public view returns (uint) {
      uint max = (offeringAmount * clearingPrice()) / 1e18;
      if (totalAmount + amount > max) {
        return max - totalAmount;
      }
      return amount;
    }

    function _deposit(address user, uint amount) private nonReentrant {
      require(!paused, 'paused');
      require(block.timestamp > startTime && block.timestamp < endTime, 'sale not active');
      require(amount > 0, 'need amount > 0');
      require(perUserCap == 0 || amount <= perUserCap, 'over per user cap');
      require(userInfo[user].amount == 0, 'already participated');

      if (votingMinimum > 0) {
          if (votingSnapshotId == 0) {
              require(votingToken.balanceOf(user) >= votingMinimum, "under minimum locked");
          } else {
              require(votingToken.balanceOfAt(user, votingSnapshotId) >= votingMinimum, "under minimum locked");
          }
      }

      uint cappedAmount = commitmentSize(amount);
      require(cappedAmount > 0, 'sale fully commited');

      // Refund user's overpayment
      if (amount - cappedAmount > 0) {
          paymentToken.transfer(user, amount - cappedAmount);
      }

      addressList.push(user);
      userInfo[user].amount = cappedAmount;
      totalAmount += cappedAmount;
      emit Deposit(user, cappedAmount);
    }

    function deposit(uint amount) external {
        _transferFrom(msg.sender, amount);
        _deposit(msg.sender, amount);
    }

    function onTokenTransfer(address user, uint amount, bytes calldata _data) external override {
        require(msg.sender == address(paymentToken), "onTokenTransfer: not paymentToken");
        _deposit(user, amount);
    }

    function harvestTokens() public nonReentrant {
      require(!paused, 'paused');

      if (saleSuccessful()) {
          require(finalized, 'not finalized');
          require(userInfo[msg.sender].amount > 0, 'have you participated?');
          require(!userInfo[msg.sender].claimedTokens, 'already claimed');

          uint amount = getOfferingAmount(msg.sender);
          require(amount > 0, 'nothing to claim');
          offeringToken.safeTransfer(msg.sender, amount);
          userInfo[msg.sender].claimedTokens = true;
          emit HarvestTokens(msg.sender, amount);
      } else {
          require(block.timestamp > endTime, 'sale not ended');
          uint amount = userInfo[msg.sender].amount;
          userInfo[msg.sender].amount = 0;
          paymentToken.safeTransfer(msg.sender, amount);
          emit HarvestRefund(msg.sender, amount);
      }
    }

    // Amount of offering token a user will receive
    function getOfferingAmount(address _user) public view returns (uint) {
        return (userInfo[_user].amount * offeringAmount) / totalAmount;
    }

    function hasHarvestedTokens(address _user) external view returns (bool) {
        return userInfo[_user].claimedTokens;
    }

    function withdrawToken(address token, uint amount) public onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function _transferFrom(address from, uint amount) private {
        uint balanceBefore = paymentToken.balanceOf(address(this));
        paymentToken.safeTransferFrom(from, address(this), amount);
        uint balanceAfter = paymentToken.balanceOf(address(this));
        require(balanceAfter - balanceBefore == amount, "_transferFrom: balance change does not match amount");
    }
}
