// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import "./IERC20Metadata.sol";

/// @title IPhantomERC20
/// @dev Phantom tokens track balances in pools / contracts
///      that do not mint an LP or a share token. Non-transferrabl.
interface IPhantomERC20 is IERC20Metadata {
    /// @dev Returns the address of the token that is staked into the tracked position
    function underlying() external view returns (address);
}
