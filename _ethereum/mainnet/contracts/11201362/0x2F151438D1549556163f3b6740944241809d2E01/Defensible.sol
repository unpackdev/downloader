// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./BannedContractList.sol";

/*
    Prevent smart contracts from calling functions unless approved by the specified whitelist.
*/
contract Defensible {
 // Only smart contracts will be affected by this modifier
  modifier defend(BannedContractList bannedContractList) {
    require(
      (msg.sender == tx.origin) || bannedContractList.isApproved(msg.sender),
      "This smart contract has not been approved"
    );
    _;
  }
}
