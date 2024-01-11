// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Initializable.sol";

/// @title BasicRNGUpgradeable Pseudo Random Generation
abstract contract BasicRNGUpgradeable is Initializable {
  /// @notice nonces
  uint256 private _nonces;

  ///@notice generate 'random' bytes
  function randomBytes() internal returns (bytes32) {
    return keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _nonces++));
  }

  ///@notice generate a 'random' number < mod
  function random(uint256 mod) internal returns (uint256) {
    return uint256(randomBytes()) % mod;
  }

  ///@notice generate a 'random' array of bool of defined size
  function randomBoolArray(uint256 size) internal returns (bool[] memory output) {
    require(size <= 256, "Exceed max size : 256");
    output = new bool[](size);
    uint256 rand = uint256(randomBytes());
    for (uint256 i; i < size; i++) output[i] = (rand >> i) & 1 == 1;
  }

  function __BasicRNG_init() internal onlyInitializing {
    __BasicRNG_init_unchained();
  }

  function __BasicRNG_init_unchained() internal onlyInitializing {}
}
