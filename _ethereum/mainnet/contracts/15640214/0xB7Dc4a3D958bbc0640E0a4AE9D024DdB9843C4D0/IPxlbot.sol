//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC721AQueryable.sol";
import "./IInventoryEntityContract.sol";
import "./IAttributeCoordinator.sol";
import "./IERC721APlayable.sol";

interface IPxlbot is
  IInventoryEntityContract,
  IAttributeCoordinator,
  IERC721AQueryable,
  IERC721APlayable
{
  function mint(uint256 amount, address to) external payable;

  function mintScion(
    address to,
    uint256 parent_id,
    string[] memory attrsIds,
    uint32[] memory attrsVals
  ) external payable;
}
