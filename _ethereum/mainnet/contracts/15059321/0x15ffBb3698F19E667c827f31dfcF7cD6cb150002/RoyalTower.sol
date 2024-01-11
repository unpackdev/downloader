// SPDX-License-Identifier: MIT

/// @title Contract that handles Queen's Palace maintenance

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

import "./BaseContractController.sol";
import "./IRoyalTower.sol";
import "./IQueenPalace.sol";

contract RoyalTower is IRoyalTower, BaseContractController {
  uint256 private nextWithdraw;
  uint256 private daoBalance;

  constructor(IQueenPalace _queenPalace) {
    _registerInterface(type(IRoyalTower).interfaceId);
    nextWithdraw = 1;
    queenPalace = _queenPalace;
  }

  /**
   * @notice DAO Treasure Balance.
   */
  function daoTreasure() external view returns (uint256) {
    return daoBalance;
  }

  // fallback function
  fallback() external payable onlyOwnerOrAuctionHouseProxy {
    _depositToDAOTreasure(msg.sender, 0, msg.value);
  }

  // receive function
  receive() external payable onlyOwnerOrAuctionHouseProxy {
    _depositToDAOTreasure(msg.sender, 0, msg.value);
  }

  /**
   * @notice receive ETH to enrich DAO treasure.
   */
  function depositToDAOTreasure(uint256 _queeneAuctionId)
    external
    payable
    nonReentrant
  {
    _depositToDAOTreasure(msg.sender, _queeneAuctionId, msg.value);
  }

  /**
   * @notice receive ETH to enrich palace treasure.
   */
  function _depositToDAOTreasure(
    address _sender,
    uint256 _queeneAuctionId,
    uint256 amount
  ) private {
    require(amount > 0, "invalid amount");

    daoBalance += amount;

    emit DAOTreasureDeposit(_sender, _queeneAuctionId, amount);
  }

  /**
   * @notice withdraw balance for Propose fund.
   */
  function withdrawFromTreasure(uint256 _amount, address payable _funded)
    external
    nonReentrant
    whenNotPaused
    onlyDAO
  {
    _withdrawFromTreasure(_funded, _amount);
  }

  /**
   * @notice withdraw balance for Palace Maintenance.
   */
  function _withdrawFromTreasure(address payable to, uint256 _amount) private {
    require(_amount <= daoBalance, "Not enough balance on treasure!");

    Address.sendValue(to, _amount);

    daoBalance -= _amount;

    emit DAOTreasureWithdraw(to, nextWithdraw++, _amount);
  }

  /**
   * @notice retrieve auction funds that went to fallback.
   */
  function retrieveAuctionFallbackFunds()
    external
    nonReentrant
    whenNotPaused
    onlyOwner
  {
    (bool success, ) = queenPalace.QueenAuctionHouseProxyAddr().call(
      abi.encodeWithSignature("withdrawFallbackFund()")
    );

    require(success, "Error retrieving fallback funds");
  }
}
