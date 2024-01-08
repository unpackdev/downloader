// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

interface IFuseMigrator {
    /// @notice Emitted on each migration
    /// @param sender msg.sender
    /// @param recipient Address receiving the new cTokens
    /// @param cToken0 cToken to migrate from
    /// @param cToken1 cToken to migrate to
    /// @param cToken0Amount Amount of cToken0 to migrate
    event Migrate(address sender, address recipient, address cToken0, address cToken1, uint256 cToken0Amount);

    /// @notice Migrates a cToken of the same underlying asset to another
    /// @dev This may put the sender at liquidation risk if they have debt
    /// @param recipient Address receiving the new cTokens
    /// @param cToken0 cToken to migrate from
    /// @param cToken1 cToken to migrate to
    /// @param token Underlying token
    /// @param cToken0Amount Amount of cToken0 to migrate
    /// @return Amount of cToken1 minted and received
    function migrate(
        address recipient,
        address cToken0,
        address cToken1,
        address token,
        uint256 cToken0Amount
    ) external returns (uint256);

    /// @notice Transfer a tokens balance left on this contract to the owner
    /// @dev Can only be called by owner
    /// @param token Address of token to transfer the balance of
    function transferToken(address token) external;
}
