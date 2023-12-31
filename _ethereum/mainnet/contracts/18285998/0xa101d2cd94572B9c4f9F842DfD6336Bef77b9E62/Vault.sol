// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./VaultERC20.sol";
import "./VaultERC721.sol";
import "./VaultETH.sol";
import "./VaultExecute.sol";
import "./VaultNewReceivers.sol";
import "./VaultIssueERC721.sol";

import "./Initializable.sol";

contract Vault is
  Initializable,
  VaultERC20,
  VaultERC721,
  VaultETH,
  VaultExecute,
  VaultNewReceivers,
  VaultIssueERC721
{
  function initialize() initializer public {
    __initializeERC20(1, 2, 11);
    __initializeERC721(3);
    __initializeETH(4, 5);
    __initializeExecute(6, 7);
    __initializeNewReceivers(8);
    __initializeIssueERC721(9);
    __initializePausable(10);
  }
}
