// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/// @title MEV Army On-Chain Trait Data
/// @author x0r

interface IMEVArmyTraitData {
    function getLegionIndex(uint256 tokenId) external view returns (uint256);
}
