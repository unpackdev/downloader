// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./VaultERC20.sol";
import "./VaultERC721.sol";
import "./VaultETH.sol";
import "./VaultExecute.sol";
import "./VaultNewReceivers.sol";
import "./VaultIssueERC721.sol";

contract Vault is
  VaultERC20,
  VaultERC721,
  VaultETH,
  VaultExecute,
  VaultNewReceivers,
  VaultIssueERC721
{
  constructor()
    VaultERC20(1, 2, 11)
    VaultERC721(3)
    VaultETH(4, 5)
    VaultExecute(6, 7)
    VaultNewReceivers(8)
    VaultIssueERC721(9)
    Pausable(10)
  {}
}
