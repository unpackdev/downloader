// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "./IERC20Minimal.sol";

interface IMarginEngine {
    /// @notice The address of the underlying (non-yield bearing) token - e.g. USDC
    /// @return The underlying ERC20 token (e.g. USDC)
    function underlyingToken() external view returns (IERC20Minimal);

    /// @notice The unix termEndTimestamp of the MarginEngine in Wad
    /// @return Term End Timestamp in Wad
    function termEndTimestampWad() external view returns (uint256);
}
