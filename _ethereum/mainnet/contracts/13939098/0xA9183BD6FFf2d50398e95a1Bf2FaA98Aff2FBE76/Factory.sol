// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Clones.sol";
import "./Buffer.sol";
contract Factory {
  event ContractDeployed(address indexed owner, address indexed group, bytes32 cid, string title);
  address public immutable implementation;
  constructor() {
    implementation = address(new Buffer());
  }
  function genesis(string memory title, bytes32 _root, bytes32 _cid) external returns (address) {
    address payable clone = payable(Clones.clone(implementation));
    Buffer buffer = Buffer(clone);
    buffer.initialize(_root);
    emit ContractDeployed(msg.sender, clone, _cid, title);
    return clone;
  }
}
