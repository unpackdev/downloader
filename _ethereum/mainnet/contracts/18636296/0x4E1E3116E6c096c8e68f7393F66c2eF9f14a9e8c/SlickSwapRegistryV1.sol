// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;
pragma abicoder v2;

// Imports
import "./Ownable.sol";
import "./ISlickSwapRegistryV1.sol";

/**
 * SlickSwapRegistryV1 - this contract stores various system settings used by
 * the individual SlickSwap wallet contracts.
 *
 * This contract is immutable (unlike wallet contracts, which are individually upgradeable).
 * Newer SlickSwap versions may introduce additional Registry contracts for new settings.
 */
contract SlickSwapRegistryV1 is Ownable, ISlickSwapRegistryV1 {
  // Storage variables
  mapping(address => bool) public _traderAddresses;
  address public _tradingFeeRecipient;
  address public _withdrawalFeeRecipient;
  address public _nextImplementation;

  /**
   * Initializes the contract and assigns the owner to the signer
   * of the deployment transaction.
   */
  constructor() {
    _owner = msg.sender;
  }

  /**
   * Returns the address that should receive fees from trading operations.
   */
  function getTradingFeeRecipient() external view returns (address) {
    return _tradingFeeRecipient;
  }

  /**
   * Returns the address that should receive fees from trading operations.
   */
  function getWithdrawalFeeRecipient() external view returns (address) {
    return _withdrawalFeeRecipient;
  }

  /**
   * Returns the address of the most up-to-date SlickSwap implementation contract.
   */
  function getNextImplementation() external view returns (address) {
    return _nextImplementation;
  }

  /**
   * Validates that the address is indeed authorized to settle SlickSwap trades.
   *
   * @param sender the address calling the trade method
   */
  function verifyTrader(address sender) external view {
    require(_traderAddresses[sender], "This address is not allowed to trade");
  }

  /**
   * Updates the address that should receive fees from trading operations.
   * Called by Registry owner.
   *
   * @param tradingFeeRecipient new trading fee recipient.
   */
  function setTradingFeeRecipient(address tradingFeeRecipient) external onlyBy(_owner) {
    _tradingFeeRecipient = tradingFeeRecipient;
  }

  /**
   * Updates the address that should receive fees from withdrawal operations.
   * Called by Registry owner.
   *
   * @param withdrawalFeeRecipient new withdrawal fee recipient
   */
  function setWithdrawalFeeRecipient(address withdrawalFeeRecipient) external onlyBy(_owner) {
    _withdrawalFeeRecipient = withdrawalFeeRecipient;
  }

  /**
   * Updates the address of the most up-to-date SlickSwap implementation contract.
   * Called by Registry owner.
   *
   * @param nextImplementation new address of the SlickSwap logic contract.
   */
  function setNextImplementation(address nextImplementation) external onlyBy(_owner) {
    _nextImplementation = nextImplementation;
  }

  /**
   * Adds/removes the address of the account authorized to perform the trades.
   * Called by Registry owner.
   *
   * @param traderAddress address in consideration
   * @param enable adding represented by true, removing by false
   */
  function enableTradingFor(address traderAddress, bool enable) external onlyBy(_owner) {
    _traderAddresses[traderAddress] = enable;
  }
}
