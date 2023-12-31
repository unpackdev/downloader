pragma solidity ^0.6.0;

import "./ApprovedContractList.sol";

/*
    Prevent smart contracts from calling functions unless approved by the specified whitelist.
*/
contract Defensible {
 // Only smart contracts will be affected by this modifier
  modifier defend(ApprovedContractList approvedContractList) {
    require(
      (msg.sender == tx.origin) || approvedContractList.isApproved(msg.sender),
      "This smart contract has not been approved"
    );
    _;
  }
}
