// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "IManualBridge.sol";
import "Ownable.sol";
import "IERC20.sol";

// This is a totally centralized (ie not trustless) manual bridge contract for DFP2
// bridging between Ethereum and Radix. Requires trust in contract owner.
contract ManualBridge is IManualBridge, Ownable {
  IERC20 constant token = IERC20(0x2F57430a6ceDA85a67121757785877b4a71b8E6D);

  uint16 constant UNLOCKED = 0x0000;
  uint16 constant LOCKED = 0x0001;
  address admin;

  Config public bridgeConfig = Config({
    locked: LOCKED,                     // 2nd bit is admin lock
    forwardBaseFee: 100,                // Base fee
    forwardFeeFraction: 655,            // Approximately 1%
    backwardBaseFee: 500,               // Base fee
    backwardFeeFraction: 655,           // Approximately 1%
    totalFees: 0                        // Total fees collected
  });

  constructor(){
    admin = 0x3C7791728AdCA8C8ca5A46d6170a9c1fd24408e2;
  }

  // used for bridge (un)lock functions which may only be called by admin or owner
  modifier onlyAdmin() {
    if (msg.sender != admin && msg.sender != owner()) { revert AdminRightsRequired(); }
    _;
  }

  /**
   * @inheritdoc IManualBridge
   */
  function bridge(
    uint256 inputAmount,
    bytes32[2] calldata radixAddress
  ) external override
  {
    Config storage c = bridgeConfig;
    if (c.locked == LOCKED) { revert BridgeLocked(); }
    if (inputAmount <= c.forwardBaseFee) { revert InsufficientInput(); }
    if (token.transferFrom(msg.sender, address(this), inputAmount) != true) { revert TokenTransferFailure(); }

    uint256 baseFee = uint256(c.forwardBaseFee) * 10**18;
    uint256 fractionalFee = (inputAmount * c.forwardFeeFraction) >> 16;
    uint256 fee = baseFee > fractionalFee ? baseFee : fractionalFee;
    c.totalFees += uint96(fee);

    emit Bridged(msg.sender, inputAmount - fee, fee, radixAddress);
  }

  /**
   * @notice Bridge tokens back from Radix to Ethereum. Release these tokens to the user.
   * @param inputAmount Amount of tokens bridged back to Ethereum.
   * @param destination Address of the user to receive the funds.
   * @param radixHash Transaction on the Radix network removing supply on Radix.
   */
  function release(
    uint256 inputAmount,
    address destination,
    bytes32[2] calldata radixHash
  ) external onlyOwner()
  {
    Config storage c = bridgeConfig;
    if (c.locked == LOCKED) { revert BridgeLocked(); }
    if (inputAmount <= c.backwardBaseFee) { revert InsufficientInput(); }

    uint256 baseFee = uint256(c.backwardBaseFee) * 10**18;
    uint256 fractionalFee = (inputAmount * c.backwardFeeFraction) >> 16;
    uint256 fee = baseFee > fractionalFee ? baseFee : fractionalFee;
    c.totalFees += uint96(fee);

    if (token.transfer(destination, inputAmount - fee) != true) { revert TokenTransferFailure(); }
    emit Released(destination, inputAmount - fee, fee, radixHash);
  }

  /**
   * @notice Sets admin address for emergency exchange locking.
   * @dev Can only be called by the owner of the contract.
   * @param adminAddress Address of the admin to set
   */
  function setAdmin(address adminAddress) external onlyOwner() {
    admin = adminAddress;
    emit AdminChanged(adminAddress);
  }

  /**
   * @notice Sets exchange lock, under which swap and liquidity add (but not remove) are disabled.
   * @dev Can only be called by the admin of the contract.
   */
  function lockBridge() external onlyAdmin() {
    bridgeConfig.locked = LOCKED;
    emit LockChanged(msg.sender, bridgeConfig.locked);
  }

  /**
   * @notice Resets exchange lock.
   * @dev Can only be called by the admin of the contract.
   */
  function unlockBridge() external onlyAdmin() {
    bridgeConfig.locked = UNLOCKED;
    emit LockChanged(msg.sender, bridgeConfig.locked);
  }

  /**
   * @notice Updates bridge fees.
   * @param newForwardBaseFee New forward base fee level in whole tokens
   * @param newForwardFeeFraction New forward fractional fee (times 2^-16)
   * @param newBackwardBaseFee New backward base fee level in whole tokens
   * @param newBackwardFeeFraction New backward fractional fee (times 2^-16)
   */
  function setFees(
    uint16 newForwardBaseFee,
    uint16 newForwardFeeFraction,
    uint16 newBackwardBaseFee,
    uint16 newBackwardFeeFraction
  ) external onlyOwner()
  {
    Config storage c = bridgeConfig;
    c.forwardBaseFee = newForwardBaseFee;
    c.forwardFeeFraction = newForwardFeeFraction;
    c.backwardBaseFee = newBackwardBaseFee;
    c.backwardFeeFraction = newBackwardFeeFraction;

    emit ConfigUpdated(c);
  }

  /**
   * @notice Claims fees collected by the bridge and transfers to selected address
   * @param destination Address that the fees will be transferred to
   */
  function claimFees(address destination) external onlyOwner() {
    Config storage c = bridgeConfig;
    uint256 totalFees = uint256(c.totalFees);
    if (token.transfer(destination, totalFees) != true) { revert TokenTransferFailure(); }
    c.totalFees = 0;

    emit FeesClaimed(totalFees);
  }
}
