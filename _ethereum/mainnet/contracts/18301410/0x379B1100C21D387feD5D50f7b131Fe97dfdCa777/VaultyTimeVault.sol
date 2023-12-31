// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract VaultyTimeVault is Ownable {
  // *********************************************************************************
  // ******************************* Vaulty Time Vault *******************************
  // *********************************************************************************

  using SafeERC20 for IERC20;

  struct Vault {
    uint256 id;
    address token;
    uint256 amount;
    uint256 unlockTime;
    uint256 penaltyPercent;
    bool isWithdrawableEarly;
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
  event CreateVault(uint256 vaultId, uint256 balance, uint256 unlockTime);
  event Withdraw(uint256 vaultId);
  event EarlyWithdraw(uint256 vaultId, uint256 amount, uint256 fee, uint256 penaltyPercent);
  event TransferVault(uint256 vaultId, address newOwner);



  // *********************************************************************************
  // ******************** Vault creation, withdrawal & transfers *********************
  // *********************************************************************************

  function createVault(
    address token,
    uint256 amount,
    uint256 unlockTime,
    bool isWithdrawableEarly,
    address owner
  ) external payable {
    require(tokenWhitelist[token], "Token is not whitelisted.");
    require(msg.value == creationFee, "Protocol fee not met");
    require(amount != 0, "Amount cannot be 0.");
    require(unlockTime > block.timestamp, "unlockTime must be in the future");
    require(owner != address(0), "Owner cannot be null.");

    // Transfer the tokens
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

    // Adjust the vaultId
    _vaultIdCounter++;
    uint256 vaultId = _vaultIdCounter;

    // Add the deposit information
    vaultInfo[vaultId] = Vault({
      id: vaultId,
      token: token,
      amount: amount,
      unlockTime: unlockTime,
      isWithdrawableEarly: isWithdrawableEarly,
      penaltyPercent: penaltyPercent,
      owner: owner
    });

    // Add the creation fee to the withdrawable fees
    creationFeePool += msg.value;

    emit CreateVault(vaultId, amount, unlockTime);
  }

  // To withdraw the tokens after the unlock timestamp
  function withdraw(uint256 vaultId) external {
    Vault storage userDeposit = vaultInfo[vaultId];

    require(userDeposit.owner == msg.sender, "Only the owner can withdraw.");
    require(
      block.timestamp >= userDeposit.unlockTime,
      "Vault is still locked."
    );
    require(userDeposit.amount != 0, "No unlocked tokens to withdraw.");

    // Update the deposit information
    uint256 amount = userDeposit.amount;
    userDeposit.amount = 0;

    // Transfer the tokens back to the withdrawer
    IERC20(userDeposit.token).safeTransfer(msg.sender, amount);

    emit Withdraw(vaultId);
  }

  function earlyWithdraw(uint256 vaultId) external {
    Vault storage userDeposit = vaultInfo[vaultId];

    require(
      userDeposit.isWithdrawableEarly,
      "Vault is not early withdrawable."
    );
    require(userDeposit.owner == msg.sender, "Only the owner can withdraw.");
    require(userDeposit.amount != 0, "No tokens to withdraw.");

    // Update the deposit information
    uint256 amount = userDeposit.amount;
    userDeposit.amount = 0;

    uint256 fee = (amount * userDeposit.penaltyPercent) / 100;
    uint256 amountToTransfer = amount - fee;

    // Transfer the tokens back to the depositor
    IERC20(userDeposit.token).safeTransfer(msg.sender, amountToTransfer);

    // Update the rewards pool
    rewardsPool[userDeposit.token] += fee;

    emit EarlyWithdraw(vaultId, amountToTransfer, fee, userDeposit.penaltyPercent);
  }

  function transferVault(uint256 vaultId, address newOwner) external payable {
    require(newOwner != address(0), "New owner cannot be null.");

    Vault storage userDeposit = vaultInfo[vaultId];

    require(
      userDeposit.owner == msg.sender,
      "Only the owner can transfer the vault."
    );

    require(
      userDeposit.amount != 0,
      "Vault with no tokens cannot be transferred."
    );

    require(msg.value == transferFee, "Protocol fee not met");

    transferFeePool += msg.value;

    // Update the owner
    userDeposit.owner = newOwner;

    emit TransferVault(vaultId, newOwner);
  }



  // *********************************************************************************
  // ************************ Managers & whitelist management ************************
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
    require(percent <= 20, "Penalty fee cannot be more than 20%");
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