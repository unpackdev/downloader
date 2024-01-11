// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import "./IERC20Metadata.sol";

/// @title IPhantomERC20
/// @dev Fantom token represents minimum needed interface to use 
interface IPhantomERC20 is IERC20Metadata {
    
    /// @dev Returns address of token connected with torenized position
    function underlying() external view returns (address);
}
