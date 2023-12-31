// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC4626.sol";
import "./IFijaACL.sol";

///
/// @title Base interface
/// @author Fija
/// @notice Interface base layer for vault and strategy interfaces
///
interface IFijaERC4626Base is IFijaACL, IERC4626 {
    ///
    /// @dev Returns the amount of tokens that the Vault would exchange for the amount of assets provided, in an ideal
    /// scenario where all the conditions are met.
    ///
    /// - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
    /// - MUST NOT show any variations depending on the caller.
    /// - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
    /// - MUST NOT revert.
    ///
    /// NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
    /// “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
    /// from.
    /// @param assets amount to be converted to tokens amount
    ///
    function convertToTokens(
        uint256 assets
    ) external view returns (uint256 tokens);
}
