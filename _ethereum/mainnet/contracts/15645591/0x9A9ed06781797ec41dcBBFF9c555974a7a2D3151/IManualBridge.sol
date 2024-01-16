// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title ManualBridge interface
 * @author Jazzer9F
 */
interface IManualBridge {
  error AdminRightsRequired();
  error TokenTransferFailure();
  error InsufficientInput();
  error BridgeLocked();

  // bridge configuration
  struct Config {
    uint16 locked;                    // variable to keep track of whether the exchnage is locked
    uint16 forwardBaseFee;            // base fee level in # of whole tokens
    uint16 forwardFeeFraction;        // variable part of fee
    uint16 backwardBaseFee;           // base fee level in # of whole tokens
    uint16 backwardFeeFraction;       // variable part of fee
    uint96 totalFees;                 // total fees currently held by the contract
  }

 /**
  * @notice Bridge the token towards Radix. Forwards the tokens to the team address.
  * @param amountToBridge Amount of tokens to bridge to Radix
  * @param radixAddress Address on the Radix public network that tokens should be sent to
  */
  function bridge(
    uint256 amountToBridge,
    bytes32[2] calldata radixAddress
  ) external;

 /**
  * @notice Emit Bridged event when tokens are bridged to the Radix network
  * @param source Address of the caller
  * @param netAmountBridged Amount of tokens sent to the Radix network (held in team wallet)
  * @param feePayed Fee withheld from the bridged amount
  * @param radixAddress The address on the Radix network that the tokens are to be sent to
  */
  event Bridged(
    address source,
    uint256 netAmountBridged,
    uint256 feePayed,
    bytes32[2] radixAddress
  );

  /**
   * @notice Emit Released event when tokens are bridged back from the Radix network
   * @param destination Address of the bridge user
   * @param radixHash Transaction on Radix network paying for this release
   * @param feePayed Amount of fee payed
   * @param amountReleased Amount of DFP2 released to the user
   */
  event Released(
    address destination,
    uint256 amountReleased,
    uint256 feePayed,
    bytes32[2] radixHash
  );

  /**
   * @notice Emit adminChanged event when the bridge config (ie fees) is updated.
   * @param newConfig The updated config struct
   */
  event ConfigUpdated(
    Config newConfig
  );

  /**
   * @notice Emit adminChanged event when the exchange admin address is changed
   * @param newAdmin Address of new admin, who can (un)lock the exchange
   */
  event AdminChanged(
    address newAdmin
  );

  /**
   * @notice Emit LockChanged event when the exchange is (un)locked by an admin
   * @param exchangeAdmin Address of the admin making the change
   * @param newLockValue The updated value of the lock variable
   */
  event LockChanged(
    address exchangeAdmin,
    uint256 newLockValue
  );

  /**
   * @notice Emit FeesClaimed when the fees collected by the bridge are claimed by the owner
   * @param amountClaimed Amount of fees withdrawn. This is always the total amount of fees collected until now.
   */
  event FeesClaimed(
    uint256 amountClaimed
  );
}
