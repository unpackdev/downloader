// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./ReservoirOracle.sol";

interface IPair is IERC20 {
  /// @notice Wraps NFTs into fractional tokens.
  /// @param tokenIds The ids of the NFTs to wrap.
  /// @param proofs The merkle proofs for the NFTs proving that they can be used in the pair.
  /// @return fractionalTokenAmount The amount of fractional tokens minted.
  function wrap(
    uint256[] calldata tokenIds,
    bytes32[][] calldata proofs,
    ReservoirOracle.Message[] calldata messages
  ) external returns (uint256 fractionalTokenAmount);
}
