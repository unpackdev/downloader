//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./IERC721.sol";

interface IBaseRegistrar is IERC721 {
  event ControllerAdded(address indexed controller);
  event ControllerRemoved(address indexed controller);
  event NameMigrated(uint256 indexed id, address indexed owner, uint256 expires);
  event NameRegistered(uint256 indexed id, address indexed owner, uint256 expires);
  event NameRenewed(uint256 indexed id, uint256 expires);

  /**
   * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
   */
  function reclaim(uint256 id, address owner) external;

  function ens() external view returns (address);
}
