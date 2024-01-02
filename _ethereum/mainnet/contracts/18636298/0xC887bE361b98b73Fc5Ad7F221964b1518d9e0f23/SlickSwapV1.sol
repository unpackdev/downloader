// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;
pragma abicoder v2;

// Imports
import "./Ownable.sol";
import "./Trading.sol";
import "./EtherHolder.sol";
import "./Withdrawable.sol";
import "./Upgradable.sol";
import "./ISlickSwapRegistryV1.sol";

/**
 * SlickSwap smart contract wallet, version 1
 *
 * This is a logic contract intended to be used with the minimal EIP-1967 proxy.
 * See {proxyDeployer} for provisioning details.
 *
 * This wallet can be used to:
 *  - deposit and hold Ether and ERC-20 tokens
 *  - withdraw Ether and ERC-20 tokens anytime by means of wallet Owner signature
 *  - perform Uniswap V3 trades by means of SlickSwap bot
 *
 * Owner keys are managed either by SlickSwap or externally (by a Web3 wallet,
 * for example). In the former case SlickSwap invokes withdrawal and logic
 * upgrade methods on Owner's behalf by explicitly passing in an ECDSA signature
 * as an argument; in the latter case the corresponding methods are invoked
 * directly from the Owner address.
 *
 * Wallet contracts are individually upgradeable - each instance can either explicitly
 * authorize the logic change by means of Owner public key, or opt out.
 */
contract SlickSwapV1 is Ownable, Trading, EtherHolder, Withdrawable, Upgradable {
  // Storage variables
  ISlickSwapRegistryV1 immutable _registry;

  /**
   * Logic contract constructor - creates the common bytecode.
   *
   * @param registry The address of the Registry contract
   */
  constructor(address registry) {
    _registry = ISlickSwapRegistryV1(registry);
  }

  /**
   * Wallet initializer - invoked on EIP-1967 proxy right after its deployment
   * to set up a new instance.
   *
   * @param owner address of the wallet Owner.
   */
  function initialize(address owner) external {
    require(_owner == address(0), "You can only initialize the contract once");
    _owner = owner;
  }

  /**
   * Logic migration method - intended to be called right after the wallet is
   * upgraded to a new logic version. The sole parameter is the address of the
   * previous logic contract. No-op as this is version 1.
   *
   * The very presence of this method is used as a safeguard against upgrades to
   * "dead" logic addresses, such as zero address, self-destructed contracts or
   * contracts with the wrong interface.
   */
  function migrate(address) override external onlyOnce returns (bool) {
    return true;
  }

  /**
   * Upgrade the contract to the latest logic version. To be called directly by the wallet Owner.
   */
  function upgrade() external onlyBy(_owner) {
    _upgrade(_registry.getNextImplementation());
  }

  /**
   * Upgrade the contract to the latest logic version. To be called on Owner's behalf.
   *
   * @param signature an ECDSA signature of the authorization with the Owner's public key
   */

  function upgrade(Signature calldata signature) external onlySignedBy(_owner, keccak256(abi.encodePacked()), signature) {
    _upgrade(_registry.getNextImplementation());
  }

  /**
   * Perform a trade. To be called by a Trader - an address listed in Registry
   * as eligible to settle trades.
   *
   * @param tradeId a unique identifier of the trade for SlickSwap internal bookkeeping
   * @param broker the type of the broker (the only supported value is 1, meaning Uniswap V3)
   * @param path token exchange path, in the format of a specific broker
   * @param flags a bitmask representing trade settings, see Trading contract for details
   * @param amountIn amount of the "source" token to trade
   * @param amountOut amount of the "destination" token to trade
   * @param amountFee amount of the "destination" taken by SlickSwap as a fee. Enforced to be less than 3%.
   *
   * @return success a flag indicating whether a swap was performed successfully
   */
  function trade(uint256 tradeId, uint8 broker, bytes memory path, uint8 flags, uint256 amountIn, uint256 amountOut, uint256 amountFee) external returns (bool success) {
    _registry.verifyTrader(msg.sender);
    return _trade(tradeId, broker, path, flags, amountIn, amountOut, amountFee, _registry.getTradingFeeRecipient());
  }

  /**
   * Token (including Ether) withdrawal. To be called directly by the wallet Owner.
   * No fee is taken.
   *
   * @param to withdrawal destination address
   * @param token the ERC-20 contract address, or zero for Ether
   * @param amount withdrawal amount
   *
   * @return bool withdrawal success flag
   */
  function withdraw(address to, address token, uint256 amount) external onlyBy(_owner) returns (bool) {
    return _withdraw(to, token, amount, 0, address(0));
  }

  /**
   * Token (including Ether) withdrawal. To be called on Owner's behalf.
   * A fixed fee is taken on top of the withdrawal amount.
   *
   * @param to withdrawal destination address
   * @param token the ERC-20 contract address, or zero for Ether
   * @param amount withdrawal amount
   * @param fee withdrawal fee
   * @param signature an ECDSA signature of the authorization with the Owner's public key
   *
   * @return bool withdrawal success flag
   */
  function withdraw(address to, address token, uint256 amount, uint256 fee, Signature calldata signature) external onlySignedBy(_owner, keccak256(abi.encodePacked(to, token, amount, fee)), signature) returns (bool) {
    return _withdraw(to, token, amount, fee, _registry.getWithdrawalFeeRecipient());
  }
}
