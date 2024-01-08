// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./IERC20.sol";
import "./CTokenInterfaces.sol";
import "./IFuseMigrator.sol";
import "./SafeERC20.sol";

/// @author Ganesh Gautham Elango
/// @title Migrates 1 cToken to another if both have the same underlying token
contract FuseMigrator is IFuseMigrator, Ownable {
    using SafeERC20 for IERC20;

    /// @dev Fallback for reciving Ether
    receive() external payable {}

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
    ) external override returns (uint256) {
        // Transfers cToken0Amount of cToken0 from msg.sender to this contract
        require(
            CTokenInterface(cToken0).transferFrom(msg.sender, address(this), cToken0Amount),
            "FuseMigrator: TransferFrom failed"
        );
        // Redeems cToken0Amount of cToken0 to this contract
        require(CErc20Interface(cToken0).redeem(cToken0Amount) == 0, "FuseMigrator: Redeem failed");
        // If token is Ether
        if (token == address(0)) {
            // Mint Ether balance worth of cToken1
            CEtherInterface(cToken1).mint{ value: address(this).balance }();
            // If token is not Ether
        } else {
            // Get received token balance
            uint256 tokenAmount = IERC20(token).balanceOf(address(this));
            // Approve tokenAmount of token to be spent by cToken1
            IERC20(token).safeApprove(cToken1, tokenAmount);
            // Mint tokenAmount token worth of cToken1 to this contract
            require(CErc20Interface(cToken1).mint(tokenAmount) == 0, "FuseMigrator: Mint failed");
        }
        // Amount of cToken1 minted
        uint256 cToken1Balance = CTokenInterface(cToken1).balanceOf(address(this));
        // Transfer cToken1Balance of cToken1 to recipient
        require(CTokenInterface(cToken1).transfer(recipient, cToken1Balance), "FuseMigrator: Transfer failed");
        // Emit event
        emit Migrate(msg.sender, recipient, cToken0, cToken1, cToken0Amount);
        // Return migrated cToken1 amount
        return cToken1Balance;
    }

    /// @notice Transfer a tokens balance left on this contract to the owner
    /// @dev Can only be called by owner
    /// @param token Address of token to transfer the balance of
    function transferToken(address token) external override onlyOwner {
        if (token == address(0)) {
            msg.sender.transfer(address(this).balance);
        } else {
            IERC20(token).safeTransfer(msg.sender, IERC20(token).balanceOf(address(this)));
        }
    }
}
