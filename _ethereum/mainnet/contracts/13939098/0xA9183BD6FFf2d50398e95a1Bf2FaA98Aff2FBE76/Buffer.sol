/////////////////////////////////////////////////////////////////////////////////////
//
//  SPDX-License-Identifier: MIT
//
//  ███    ███  ██████  ███    ██ ███████ ██    ██ ██████  ██ ██████  ███████
//  ████  ████ ██    ██ ████   ██ ██       ██  ██  ██   ██ ██ ██   ██ ██     
//  ██ ████ ██ ██    ██ ██ ██  ██ █████     ████   ██████  ██ ██████  █████  
//  ██  ██  ██ ██    ██ ██  ██ ██ ██         ██    ██      ██ ██      ██     
//  ██      ██  ██████  ██   ████ ███████    ██    ██      ██ ██      ███████
//
//  ██████  ██    ██ ███████ ███████ ███████ ██████  
//  ██   ██ ██    ██ ██      ██      ██      ██   ██ 
//  ██████  ██    ██ █████   █████   █████   ██████  
//  ██   ██ ██    ██ ██      ██      ██      ██   ██ 
//  ██████   ██████  ██      ██      ███████ ██   ██ 
//
//  https://moneypipe.xyz
//
/////////////////////////////////////////////////////////////////////////////////////
pragma solidity ^0.8.4;
import "./Initializable.sol";
contract Buffer is Initializable {
  mapping (address => uint) public withdrawn;
  bytes32 public root;
  uint public totalReceived;
  function initialize(bytes32 _root) initializer public {
    root = _root;
  }
  receive () external payable {
    totalReceived += msg.value;
  }
  function withdraw(address account, uint256 amount, bytes32[] calldata proof) external payable {
    // 1. verify proof
    bytes32 hash = keccak256(abi.encodePacked(account, amount));
    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];
      if (hash <= proofElement) {
        hash = _hash(hash, proofElement);
      } else {
        hash = _hash(proofElement, hash);
      }
    }
    require(hash == root, "1");
    // 2. calculate amount to withdraw based on "amount" (out of 1,000,000,000,000)
    uint payment = totalReceived * amount / 10**12 - withdrawn[account];
    withdrawn[account] += payment;
    _transfer(account, payment);
  }
  // memory optimization from: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/3039
  function _hash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
    assembly {
      mstore(0x00, a)
      mstore(0x20, b)
      value := keccak256(0x00, 0x40)
    }
  }
  // adopted from https://github.com/lexDAO/Kali/blob/main/contracts/libraries/SafeTransferLib.sol
  error TransferFailed();
  function _transfer(address to, uint256 amount) internal {
    bool callStatus;
    assembly {
      callStatus := call(gas(), to, amount, 0, 0, 0, 0)
    }
    if (!callStatus) revert TransferFailed();
  }
}
