//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IVoters.sol";
import "./IERC677Receiver.sol";

interface IStaking {
    function deposit(uint amount, address to) external;
}

interface ITiers {
    function userInfos(address user) external view returns (uint256, uint256, uint256);
    function userInfoTotal(address user) external view returns (uint256, uint256);
}

contract SaleFcfs is IERC677Receiver, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Represents a sale participant
    struct UserInfo {
        // Amount of payment token deposited / purchased
        uint amount;
        // Wether they already claimed their tokens
        bool claimed;
    }

    uint public constant PRECISION = 1e8;
    // Time alloted to claim tiers allocations
    uint public constant ALLOCATION_DURATION = 7200; // 2 hours
    // The raising token
    IERC20 public immutable paymentToken;
    // The offering token
    IERC20 public immutable offeringToken;
    // The vXRUNE Token
    IERC20 public immutable vxrune;
    // The time (unix seconds) when sale starts
    uint public immutable startTime;
    // The time (unix security) when sale ends
    uint public immutable endTime;
    // Total amount of offering tokens that will be offered
    uint public offeringAmount;
    // Total amount of raising tokens that need to be raised
    uint public raisingAmount;
    // Total amount of raising tokens that can be raised from tiers
    uint public raisingAmountTiers;
    // Maximum a user can contribute
    uint public immutable perUserCap;
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
    // SingleStaking: Contract
    IStaking public immutable staking;
    // Tiers: Contract
    ITiers public tiers;
    // Tiers: Size of guaranteed allocation
    uint public tiersAllocation;
    // Tiers: levels
    uint[] public tiersLevels;
    // Tiers: multipliers
    uint[] public tiersMultipliers;

    event PausedToggled(bool paused);
    event TiersConfigured(address tiersContract, uint allocation, uint[] levels, uint[] multipliers);
    event RaisingAmountSet(uint amount);
    event AmountsSet(uint offering, uint raising, uint raisingTiers);
    event Deposit(address indexed user, uint amount);
    event Harvest(address indexed user, uint amount);

    constructor(
        address _paymentToken,
        address _offeringToken,
        address _vxrune,
        uint _startTime,
        uint _endTime,
        uint _offeringAmount,
        uint _raisingAmount,
        uint _raisingAmountTiers,
        uint _perUserCap,
        address _staking
    ) Ownable() {
        paymentToken = IERC20(_paymentToken);
        offeringToken = IERC20(_offeringToken);
        vxrune = IERC20(_vxrune);
        startTime = _startTime;
        endTime = _endTime;
        offeringAmount = _offeringAmount;
        raisingAmount = _raisingAmount;
        raisingAmountTiers = _raisingAmountTiers;
        perUserCap = _perUserCap;
        staking = IStaking(_staking);
        require(_paymentToken != address(0) && _offeringToken != address(0), "!zero");
        require(_paymentToken != _offeringToken, "payment != offering");
        require(_offeringAmount > 0, "offering > 0");
        require(_raisingAmount > 0, "raising > 0");
        require(_startTime > block.timestamp, "start > now");
        require(_startTime + ALLOCATION_DURATION < _endTime, "start < end");
        require(_startTime < 1e10, "start time not unix");
        require(_endTime < 1e10, "start time not unix");
    }

    function configureTiers(
        address tiersContract,
        uint allocation,
        uint[] calldata levels,
        uint[] calldata multipliers
    ) external onlyOwner {
        tiers = ITiers(tiersContract);
        tiersAllocation = allocation;
        tiersLevels = levels;
        tiersMultipliers = multipliers;
        emit TiersConfigured(tiersContract, allocation, levels, multipliers);
    }

    function setRaisingAmount(uint amount) external onlyOwner {
      require(block.timestamp < startTime && totalAmount == 0, "sale started");
      raisingAmount = amount;
      emit RaisingAmountSet(amount);
    }

    function setAmounts(uint offering, uint raising, uint raisingTiers) external onlyOwner {
      require(block.timestamp < startTime && totalAmount == 0, "sale started");
      offeringAmount = offering;
      raisingAmount = raising;
      raisingAmountTiers = raisingTiers;
      emit AmountsSet(offering, raising, raisingTiers);
    }

    function togglePaused() external onlyOwner {
        paused = !paused;
        emit PausedToggled(paused);
    }

    function finalize() external {
        require(msg.sender == owner() || block.timestamp > endTime + 30 days, "not allowed");
        finalized = true;
    }

    function getAddressListLength() external view returns (uint) {
        return addressList.length;
    }

    function getParams() external view returns (uint, uint, uint, uint, uint, uint, uint, bool, bool) {
        return (startTime, endTime, raisingAmount, offeringAmount, raisingAmountTiers, perUserCap, totalAmount, paused, finalized);
    }

    function getTiersParams() external view returns (uint, uint[] memory, uint[] memory) {
        return (tiersAllocation, tiersLevels, tiersMultipliers);
    }

    function getOfferingAmount(address _user) public view returns (uint) {
        return (userInfo[_user].amount * offeringAmount) / raisingAmount;
    }

    function getUserAllocation(address user) public view returns (uint, uint) {
        // Allocation is zero if user just joined / changed tiers, or is not in tiers
        (, uint lastDeposit,) = tiers.userInfos(user);
        if (lastDeposit >= startTime || lastDeposit == 0) {
          return (0, 0);
        }

        // Find the highest tiers and use that allocation amount
        uint allocation = 0;
        (, uint tiersTotal) = tiers.userInfoTotal(user);
        for (uint i = 0; i < tiersLevels.length; i++) {
            if (tiersTotal >= tiersLevels[i]) {
                allocation = (tiersAllocation * tiersMultipliers[i]) / PRECISION;
            }
        }
        return (allocation, tiersTotal);
    }

    function _deposit(address user, uint amount) private nonReentrant {
        require(!paused, "paused");
        require(block.timestamp >= startTime && block.timestamp <= endTime, "sale not active");
        require(amount > 0, "need amount > 0");
        require(totalAmount < raisingAmount, "sold out");

        if (userInfo[user].amount == 0) {
            addressList.push(address(user));
        }

        // Check tiers and cap purchase to allocation
        (uint allocation, uint tiersTotal) = getUserAllocation(user);
        if (block.timestamp < startTime + ALLOCATION_DURATION) {
            require(userInfo[user].amount + amount <= allocation, "over allocation size");
            require(totalAmount + amount <= raisingAmountTiers, "reached phase 1 total cap");
        } else {
            require(perUserCap == 0 || userInfo[user].amount + amount <= allocation + perUserCap, "over per user cap");
            require(vxrune.balanceOf(user) >= 100 || tiersTotal >= 100, "minimum 100 vXRUNE or staked to participate");
        }

        // Refund any payment amount that would bring up over the raising amount
        if (totalAmount + amount > raisingAmount) {
            paymentToken.safeTransfer(user, (totalAmount + amount) - raisingAmount);
            amount = raisingAmount - totalAmount;
        }

        userInfo[user].amount = userInfo[user].amount + amount;
        totalAmount = totalAmount + amount;
        emit Deposit(user, amount);
    }

    function deposit(uint amount) external {
        _transferFrom(msg.sender, amount);
        _deposit(msg.sender, amount);
    }

    function onTokenTransfer(address user, uint amount, bytes calldata _data) external override {
        require(msg.sender == address(paymentToken), "onTokenTransfer: not paymentToken");
        _deposit(user, amount);
    }

    function harvest(bool stake) external nonReentrant {
        require(!paused, "paused");
        require(block.timestamp > endTime, "sale not ended");
        require(finalized, "not finalized");
        require(userInfo[msg.sender].amount > 0, "have you participated?");
        require(!userInfo[msg.sender].claimed, "nothing to harvest");
        userInfo[msg.sender].claimed = true;
        uint amount = getOfferingAmount(msg.sender);

        if (stake) {
            require(address(staking) != address(0), "no staking available");
            offeringToken.approve(address(staking), amount);
            staking.deposit(amount, msg.sender);
        } else {
            offeringToken.safeTransfer(address(msg.sender), amount);
        }

        emit Harvest(msg.sender, amount);
    }

    function withdrawToken(address token, uint amount) external onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function _transferFrom(address from, uint amount) private {
        uint balanceBefore = paymentToken.balanceOf(address(this));
        paymentToken.safeTransferFrom(from, address(this), amount);
        uint balanceAfter = paymentToken.balanceOf(address(this));
        require(balanceAfter - balanceBefore == amount, "_transferFrom: balance change does not match amount");
    }
}
