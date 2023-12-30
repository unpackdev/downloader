// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./FauxblocksLib.sol";
import "./StringLib.sol";
import "./RevertDecoderLib.sol";
import "./IPolicy.sol";

contract FauxblocksController {
  using FauxblocksLib for *;
  using StringLib for *;
  uint256 public signaturesRequired;
  mapping(address => bool) public authorizedSigners;
  mapping(address => mapping(uint256 => bool)) public noncesUsed;
  mapping(address => address) public policies;
  modifier onlyAuthorized {
    require(authorizedSigners[msg.sender], "unauthorized sender");
    _;
  }
  modifier onlySelf {
    require(msg.sender == address(this));
    _;
  }
  event FauxblocksSetAuthorized(address indexed user, bool isAuthorized);
  event FauxblocksSetPolicy(address indexed target, address policy);
  event FauxblocksSetThreshold(uint256 amount);
  function setAuthorized(address user, bool isAuthorized) public onlySelf {
    authorizedSigners[user] = isAuthorized;
    emit FauxblocksSetAuthorized(user, isAuthorized);
  }
  function setThreshold(uint256 threshold) public onlySelf {
    signaturesRequired = threshold;
    emit FauxblocksSetThreshold(threshold);
  }
  function setPolicy(address target, address policy) public onlySelf {
    policies[target] = policy;
    emit FauxblocksSetPolicy(target, policy);
  }
  function executeRestricted(FauxblocksLib.Transaction memory trx) public payable returns (bytes memory result) {
    address policy = policies[trx.to];
    require(policy != address(0), abi.encodePacked("policy not set for target ", trx.to.toString()).toString());
    (FauxblocksLib.TransactionType code, bytes memory data) = IPolicy(policy).acceptTransaction(msg.sender, trx);
    require(code != FauxblocksLib.TransactionType.REJECT, abi.encodePacked("policy rejected transaction with reason: ", string(data)).toString());
    return trx.packContext(address(this), data).sendTransaction(code);
  }
  function execute(FauxblocksLib.Transaction memory trx, FauxblocksLib.Approval[] memory approvals) public returns (bytes memory result) {
    require(approvals.length >= signaturesRequired, "insufficient signatures provided");
    address[] memory userSet = new address[](approvals.length);
    for (uint256 i = 0; i < approvals.length; i++) {
      address user = trx.recoverAddress(approvals[i]);
      userSet[i] = user;
      require(!noncesUsed[user][i], abi.encodePacked("nonce already used for ", user.toString()).toString());
      require(authorizedSigners[user], abi.encodePacked("unauthorized signer ", user.toString()).toString());
    }
    require(userSet.allUnique(), "duplicate addresses found");
    
    return trx.sendTransaction(FauxblocksLib.TransactionType.CALL);
  }
}
