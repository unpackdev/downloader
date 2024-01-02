//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @notice Interface for communicating with WSTBT contract
interface IWstbt {
    function stbtAddress() external view returns (address);
    function getStbtByWstbt(uint256 wstbtAmount) external view returns (uint256);
    function unwrap(uint256 unwrappedShares) external returns (uint);
    function totalSupply() external view returns (uint256);
}
