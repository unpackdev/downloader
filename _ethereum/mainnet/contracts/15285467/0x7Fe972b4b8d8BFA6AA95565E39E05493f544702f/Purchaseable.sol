// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./Pausable.sol";

// @author rollauver.eth

abstract contract Purchaseable is Ownable, Pausable {
  function purchaseHelper(address to, uint256 count)
    internal virtual;

  function earlyPurchaseHelper(address to, uint256 count)
    internal virtual;

  function isPreSaleActive() public view virtual returns (bool);

  function isPublicSaleActive() public view virtual returns (bool);
}
