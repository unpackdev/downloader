// SPDX-License-Identifier: MIT

/// @title Contract that handles QueenE's treasure claim from whitelisted holders

/************************************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░██░░░░░░░░░░░░████░░░░░░░░░░░░██░░░░░░░ *
 * ░░░░░████░░░░░░░░░░██░░██░░░░░░░░░░████░░░░░░ *
 * ░░░░██████░░░░░░░░██░░░░██░░░░░░░░██████░░░░░ *
 * ░░░███░░███░░░░░░████░░████░░░░░░███░░███░░░░ *
 * ░░██████████░░░░████████████░░░░██████████░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░███░░░░███████████░░░░███████████░░░░███░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░████████████████████████████████████████░░░ *
 *************************************************/

pragma solidity ^0.8.9;

import "./Address.sol";

import "./IQueenE.sol";
import "./IQueenETreasureClaim.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ERC165Storage.sol";
import "./EnumerableSet.sol";

contract QueenETreasureClaim is
  ERC165Storage,
  Pausable,
  ReentrancyGuard,
  Ownable,
  IQueenETreasureClaim
{
  using EnumerableSet for EnumerableSet.AddressSet;

  uint256 private claimPoolBalance;

  EnumerableSet.AddressSet internal whitelist;
  mapping(address => bool) internal queenesClaimed; //wallet claim status
  mapping(address => uint256) internal internalWhitelist; //wallet and value available

  constructor() {
    _registerInterface(type(IQueenETreasureClaim).interfaceId);
  }

  /**
   * @notice Claim Pool Balance.
   */
  function claimPool() external view returns (uint256) {
    return claimPoolBalance;
  }

  /**
   * @notice Claim Pool Balance.
   */
  function walletStatus(
    address wallet
  ) external view returns (bool whiteListed, bool claimed, uint256 value) {
    return (
      whitelist.contains(wallet),
      queenesClaimed[wallet],
      internalWhitelist[wallet]
    );
  }

  /**
   * @notice Fetch WhiteList wallets.
   */
  function walletsWhiteListed() external view returns (address[] memory list) {
    return whitelist.values();
  }

  // fallback function
  fallback() external payable {
    _depositToClaimPool(msg.sender, msg.value);
  }

  // receive function
  receive() external payable {
    _depositToClaimPool(msg.sender, msg.value);
  }

  /**
   * @notice receive ETH to claim pool.
   */
  function depositToClaimPool(
    address _sender,
    uint256 amount
  ) external payable {
    _depositToClaimPool(_sender, amount);
  }

  /**
   * @notice receive ETH to enrich claim pool.
   */
  function _depositToClaimPool(address _sender, uint256 amount) private {
    require(amount > 0, "invalid amount");

    claimPoolBalance += amount;

    emit ClaimPoolDeposit(_sender, amount);
  }

  /**
   * @notice withdraw balance from Claim Pool.
   */
  function withdrawnFromClaimPool() external nonReentrant whenNotPaused {
    address payable to = payable(msg.sender);

    require(internalWhitelist[to] > 0, "Not Whitelisted");
    require(!queenesClaimed[to], "Wallet already claimed from pool!");

    uint256 valueToClaim = internalWhitelist[to];

    require(valueToClaim <= claimPoolBalance, "Not enough funds in claim pool");
    require(valueToClaim > 0, "Cant claim ZERO");

    (bool success, ) = to.call{value: valueToClaim}("");

    require(success, "Claim error! Not Completed");

    queenesClaimed[to] = true;

    claimPoolBalance -= valueToClaim;

    emit ClaimPoolwithdraw(to, valueToClaim);
  }

  /**
   * @notice update white list.
   */
  function updateWhiteList(sWhitelist[] calldata _list) external onlyOwner {
    for (uint256 idx = 0; idx < _list.length; idx++) {
      address wallet = _list[idx].wallet;
      uint256 value = _list[idx].value;

      //add to whitelist
      if (!whitelist.contains(wallet)) whitelist.add(wallet);

      //set value in internal list
      internalWhitelist[wallet] = value;
    }
  }

  /**
   * @notice drop wallets from white list.
   */
  function dropFromWhiteList(sWhitelist[] calldata _list) external onlyOwner {
    for (uint256 idx = 0; idx < _list.length; idx++) {
      address wallet = _list[idx].wallet;

      //add to whitelist
      if (whitelist.contains(wallet)) whitelist.remove(wallet);

      //set value in internal list
      internalWhitelist[wallet] = 0;
    }
  }

  /**
   * @notice panic withdrawn of funds.
   */
  function panicWithdrawn() external onlyOwner {
    require(claimPoolBalance > 0, "Cant claim ZERO");

    address payable _owner = payable(owner());

    (bool success, ) = _owner.call{value: claimPoolBalance}("");

    require(success, "Panice Claim error! Not Completed");

    claimPoolBalance = 0;
  }
}
