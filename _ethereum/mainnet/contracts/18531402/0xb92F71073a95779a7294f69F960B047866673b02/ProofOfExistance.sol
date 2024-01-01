// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract ProofOfExistance {
  mapping (string => uint) _block;
  mapping (string => address ) _owner;

  function put(string memory hash) public {
    require(_block[hash] == 0, "hash already exists");
    _block[hash] = block.number;
    _owner[hash] = msg.sender;
  }

  function get(string memory hash) public view returns (uint, address) {
    return (_block[hash], _owner[hash]);
  }
}