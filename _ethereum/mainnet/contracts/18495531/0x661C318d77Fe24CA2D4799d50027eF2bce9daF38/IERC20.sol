// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC20Upgradeable.sol";

/// @notice Interface for the ERC20 token contract
interface IERC20 is IERC20Upgradeable {
    /// @notice Returns the number of decimals used by the token
    /// @return The number of decimals
    function decimals() external view returns (uint8);

    /// dev Returns the name of the Wrapped Ether token.
    /// return A string representing the token name.
    function name() external view returns (string memory);

    /// dev Returns the symbol of the Wrapped Ether token.
    /// return A string representing the token symbol.
    function symbol() external view returns (string memory);
}
