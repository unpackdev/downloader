// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract VaultyGoalVault is Ownable {
  // *********************************************************************************
  // ******************************* Vaulty Goal Vault *******************************
  // *********************************************************************************

  using SafeERC20 for IERC20;

  struct Vault {
    uint256 id;
    address token;
    uint256 goal;
    uint256 balance;
    bool isWithdrawableEarly;
    uint256 penaltyPercent;
    address owner;
  }

  // Whitelist management
  address public whitelistManager;
  mapping(address => bool) public tokenWhitelist;
  address public rewardsManager;

  // Vault information
  uint256 public _vaultIdCounter;
  mapping(uint256 => Vault) public vaultInfo;

  // Protocol fees
  uint256 public creationFee = 0.005 ether;
  uint256 public penaltyPercent = 15;
  uint256 public transferFee = 0.00135 ether;

  // Protocol fee pools
  uint256 private creationFeePool;
  uint256 private transferFeePool;
  mapping(address => uint256) public rewardsPool;

  // Events
  event CreateGoal(uint256 vaultId, uint256 balance, uint256 goal);
  event DepositGoal(uint256 vaultId, uint256 amount);
  event Withdraw(uint256 vaultId);
  event EarlyWithdraw(uint256 vaultId, uint256 amount, uint256 fee, uint256 penaltyPercent);
  event TransferVault(uint256 vaultId, address newOwner);



  // *********************************************************************************
  // ********************* Goal creation, withdrawal & transfers *********************
  // *********************************************************************************

  function createGoal(
    address token,
    uint256 goal,
    uint256 amount,
    address owner,
    bool isWithdrawableEarly
  ) external payable {
    require(msg.value == creationFee, "Protocol fee not met.");
    require(tokenWhitelist[token], "Token is not whitelisted.");
    require(amount != 0, "Inital deposit cannot be 0.");
    require(goal > amount, "Goal must be greater than the intial deposit.");
    require(owner != address(0), "Owner cannot be null.");

    // Transfer the token
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

    // Adjust the vaultId
    _vaultIdCounter++;
    uint256 vaultId = _vaultIdCounter;
    Vault storage userGoal = vaultInfo[vaultId];

    // Create the goal
    userGoal.id = vaultId;
    userGoal.token = token;
    userGoal.goal = goal;
    userGoal.balance = amount;
    userGoal.isWithdrawableEarly = isWithdrawableEarly;
    userGoal.penaltyPercent = penaltyPercent;
    userGoal.owner = owner;

    // Add the creation fee to the withdrawable fees
    creationFeePool += msg.value;

    emit CreateGoal(vaultId, amount, goal);
  }

  function deposit(uint256 vaultId, uint256 amount) external {
    Vault storage userGoal = vaultInfo[vaultId];

    require(userGoal.balance != 0, "Vault already closed.");
    require(amount != 0, "Deposit cannot be 0.");

    // Transfer the token
    IERC20(userGoal.token).safeTransferFrom(msg.sender, address(this), amount);

    // Update the balance
    userGoal.balance += amount;

    emit DepositGoal(vaultId, amount);
  }

  function withdraw(uint256 vaultId) external {
    Vault storage userGoal = vaultInfo[vaultId];

    require(
      userGoal.owner == msg.sender,
      "Only the specified user can withdraw."
    );
    require(userGoal.balance >= userGoal.goal, "Goal not reached yet.");

    uint256 amount = userGoal.balance;
    userGoal.balance = 0;

    IERC20(userGoal.token).safeTransfer(msg.sender, amount);

    emit Withdraw(vaultId);
  }

  function earlyWithdraw(uint256 vaultId) external {
    Vault storage userGoal = vaultInfo[vaultId];

    require(
      userGoal.owner == msg.sender,
      "Only the specified user can withdraw."
    );
    require(userGoal.isWithdrawableEarly, "Not withdrawable early.");
    require(userGoal.balance != 0, "No tokens to withdraw.");

    // Adjust for penalties
    uint256 penaltyAmount = (userGoal.balance * userGoal.penaltyPercent) / 100;
    uint256 amount = userGoal.balance - penaltyAmount;
    userGoal.balance = 0;

     // Transfer the token
    IERC20(userGoal.token).safeTransfer(msg.sender, amount);

    // Update the rewards pool
    rewardsPool[userGoal.token] += penaltyAmount;

    emit EarlyWithdraw(vaultId, amount, penaltyAmount, userGoal.penaltyPercent);
  }

  function transferVault(uint256 vaultId, address newOwner) external payable {
    require(newOwner != address(0), "New owner cannot be null.");

    Vault storage userGoal = vaultInfo[vaultId];

    require(
      userGoal.owner == msg.sender,
      "Only the owner can transfer the vault."
    );

    require(
      userGoal.balance != 0,
      "Vault with no tokens cannot be transferred."
    );
    
    require(msg.value == transferFee, "Protocol fee not met.");

    transferFeePool += msg.value;

    // Update the owner
    userGoal.owner = newOwner;

    emit TransferVault(vaultId, newOwner);
  }



  // *********************************************************************************
  // ************************ Manager & whitelist management *************************
  // *********************************************************************************

  function setWhitelistToken(address token, bool status) external payable {
    // Require the caller to be the whitelist manager
    require(
      msg.sender == whitelistManager,
      "Only the whitelist manager can update the whitelist."
    );

    // Check the token is not null
    require(token != address(0), "Token address cannot be 0");

    tokenWhitelist[token] = status;
  }

  function setWhitelistManager(address manager) external payable onlyOwner {
    require(manager != address(0), "Whitelist manager cannot be null.");
    whitelistManager = manager;
  }

  function setRewardsManager(address manager) external payable onlyOwner {
    require(manager != address(0), "Rewards manager cannot be null.");
    rewardsManager = manager;
  }



  // *********************************************************************************
  // ************************** Protocol fee configuration ***************************
  // *********************************************************************************

  function withdrawCreationFees() external payable onlyOwner {
    uint256 amount = creationFeePool;
    require(amount != 0, "No fees to withdraw.");

    // Reset the creation fee pool
    creationFeePool = 0;

    // Transfer the fees
    payable(owner()).transfer(amount);
  }

  function setCreationFee(uint256 fee) external payable onlyOwner {
    creationFee = fee;
  }

  function setPenaltyPercent(uint256 percent) external payable onlyOwner {
    require(percent <= 20, "Penalty fee cannot be more than 20%.");
    penaltyPercent = percent;
  }

  function setTransferFee(uint256 fee) external payable onlyOwner {
    transferFee = fee;
  }

  function withdrawTransferFees() external payable onlyOwner {
    require(transferFeePool > 0, "No fees to withdraw.");

    uint256 amount = transferFeePool;
    transferFeePool = 0;

    // Transfer the fees
    payable(owner()).transfer(amount);
  }

  function withdrawRewards(address token) external payable {
    require(
      msg.sender == rewardsManager,
      "Only the reward manager can withdraw rewards."
    );

    uint256 amount = rewardsPool[token];
    rewardsPool[token] = 0;

    IERC20(token).safeTransfer(rewardsManager, amount);
  }



  // *********************************************************************************
  // ********************* Contract ownership transfer functions *********************
  // *********************************************************************************

  address public pendingOwner;
  uint256 public ownerChangeTimeout;

  function startOwnershipTransfer(address newOwner) external payable onlyOwner {
    pendingOwner = newOwner;
    ownerChangeTimeout = block.timestamp + 600; // 10 minutes
  }

  function completeOwnershipTransfer() external payable {
    require(
      msg.sender == pendingOwner,
      "Only the pending owner can confirm the change."
    );
    require(
      block.timestamp < ownerChangeTimeout,
      "Ownership transfer has timed out."
    );

    _transferOwnership(pendingOwner);

    ownerChangeTimeout = 0;
    pendingOwner = address(0);
  }

  function cancelOwnershipTransfer() external payable {
    // Either the current owner or the pending owner can cancel the transfer
    require(
      msg.sender == pendingOwner || msg.sender == owner(),
      "Only the pending owner or the current owner can cancel the change."
    );

    ownerChangeTimeout = 0;
    pendingOwner = address(0);
  }

  function _transferOwnership(address newOwner) internal override {
    super._transferOwnership(newOwner);
  }



  // Created by Ashwin for Vaulty with Love (and a lot of coffee).
}