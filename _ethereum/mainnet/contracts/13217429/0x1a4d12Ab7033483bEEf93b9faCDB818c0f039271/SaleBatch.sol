//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IVoters.sol";
import "./IERC677Receiver.sol";

contract SaleBatch is IERC677Receiver, Ownable, ReentrancyGuard {
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

    // The raising token
    IERC20 public paymentToken;
    // The offering token
    IERC20 public offeringToken;
    // The time (unix seconds) when sale starts
    uint public startTime;
    // The time (unix security) when sale ends
    uint public endTime;
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
    // Wether the sale is finalized
    bool public finalized;
    // Total amount of raising tokens that have already been raised
    uint public totalAmount;
    // User's participation info
    mapping(address => UserInfo) public userInfo;
    // Participants list
    address[] public addressList;

    event Deposit(address indexed user, uint amount);
    event HarvestRefund(address indexed user, uint amount);
    event HarvestTokens(address indexed user, uint amount);

    constructor(
        address _paymentToken,
        address _offeringToken,
        uint _startTime,
        uint _endTime,
        uint _offeringAmount,
        uint _raisingAmount,
        uint _perUserCap
    ) Ownable() {
        paymentToken = IERC20(_paymentToken);
        offeringToken = IERC20(_offeringToken);
        startTime = _startTime;
        endTime = _endTime;
        offeringAmount = _offeringAmount;
        raisingAmount = _raisingAmount;
        perUserCap = _perUserCap;
        require(_paymentToken != address(0) && _offeringToken != address(0), "!zero");
        require(_paymentToken != _offeringToken, "payment != offering");
        require(_offeringAmount > 0, "offering > 0");
        require(_raisingAmount > 0, "raising > 0");
        require(_startTime > block.timestamp, "start > now");
        require(_startTime < _endTime, "start < end");
        require(_startTime < 10000000000, "start time not unix");
        require(_endTime < 10000000000, "start time not unix");
    }

    function configureVotingToken(
        uint minimum,
        address token,
        uint snapshotId
    ) public onlyOwner {
        votingMinimum = minimum;
        votingToken = IVoters(token);
        votingSnapshotId = snapshotId;
    }

    function setRaisingAmount(uint amount) public onlyOwner {
      require(block.timestamp < startTime && totalAmount == 0, "sale started");
      raisingAmount = amount;
    }

    function togglePaused() public onlyOwner {
        paused = !paused;
    }

    function finalize() public {
        require(msg.sender == owner() || block.timestamp > endTime + 14 days, "not allowed");
        finalized = true;
    }

    function getAddressListLength() external view returns (uint) {
        return addressList.length;
    }

    function getParams() external view returns (uint, uint, uint, uint, uint, uint, bool, bool) {
        return (startTime, endTime, raisingAmount, offeringAmount, perUserCap, totalAmount, paused, finalized);
    }

    function getVotingParams() external view returns (uint, address, uint) {
        return (votingMinimum, address(votingToken), votingSnapshotId);
    }

    function _deposit(address user, uint amount) private nonReentrant {
        require(!paused, "paused");
        require(block.timestamp >= startTime && block.timestamp <= endTime, "sale not active");
        require(amount > 0, "need amount > 0");
        require(perUserCap == 0 || userInfo[user].amount + amount <= perUserCap, "over per user cap");

        if (votingMinimum > 0) {
            if (votingSnapshotId == 0) {
                require(votingToken.balanceOf(user) >= votingMinimum, "under minimum locked");
            } else {
                require(votingToken.balanceOfAt(user, votingSnapshotId) >= votingMinimum, "under minimum locked");
            }
        }

        if (userInfo[user].amount == 0) {
            addressList.push(address(user));
        }

        userInfo[user].amount = userInfo[user].amount + amount;
        totalAmount = totalAmount + amount;
        emit Deposit(user, amount);
    }

    function deposit(uint amount) public {
        _transferFrom(msg.sender, amount);
        _deposit(msg.sender, amount);
    }

    function onTokenTransfer(address user, uint amount, bytes calldata _data) public override {
        require(msg.sender == address(paymentToken), "onTokenTransfer: not paymentToken");
        _deposit(user, amount);
    }

    function harvestRefund() public nonReentrant {
        require(!paused, "paused");
        require(block.timestamp > endTime, "sale not ended");
        require(userInfo[msg.sender].amount > 0, "have you participated?");
        require(!userInfo[msg.sender].claimedRefund, "nothing to harvest");
        userInfo[msg.sender].claimedRefund = true;
        uint amount = getRefundingAmount(msg.sender);
        if (amount > 0) {
            paymentToken.safeTransfer(address(msg.sender), amount);
        }
        emit HarvestRefund(msg.sender, amount);
    }

    function harvestTokens() public nonReentrant {
        require(!paused, "paused");
        require(block.timestamp > endTime, "sale not ended");
        require(finalized, "not finalized");
        require(userInfo[msg.sender].amount > 0, "have you participated?");
        require(!userInfo[msg.sender].claimedTokens, "nothing to harvest");
        userInfo[msg.sender].claimedTokens = true;
        uint amount = getOfferingAmount(msg.sender);
        if (amount > 0) {
            offeringToken.safeTransfer(address(msg.sender), amount);
        }
        emit HarvestTokens(msg.sender, amount);
    }

    function harvestAll() public {
        harvestRefund();
        harvestTokens();
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
