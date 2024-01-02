// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

import "./IERC20Metadata.sol";

/// @title Interface of ERC20 tokens that can be burned (as part of the "SwarmX.eth Protocol")
/// @notice Interface for an ERC20 token with a burn function.
/// @dev Extends the IERC20 interface with a burn function for token burning capabilities.
/// @author Swarm
interface IERC20Burner is IERC20Metadata {
    function burn(uint256 amount) external;
}
