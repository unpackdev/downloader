// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev This interfaces defines the functions of the KeeperDAO liquidity pool
/// that our contract needs to know about. The only function we need is the
/// borrow function, which allows us to take flash loans from the liquidity
/// pool.
interface ILiquidityPool {
    /// @dev Borrow ETH/ERC20s from the liquidity pool. This function will (1)
    /// send an amount of tokens to the `msg.sender`, (2) call
    /// `msg.sender.call(_data)` from the KeeperDAO borrow proxy, and then (3)
    /// check that the balance of the liquidity pool is greater than it was
    /// before the borrow.
    ///
    /// @param _token The address of the ERC20 to be borrowed. ETH can be
    /// borrowed by specifying "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE".
    /// @param _amount The amount of the ERC20 (or ETH) to be borrowed. At least
    /// more than this amount must be returned to the liquidity pool before the
    /// end of the transaction, otherwise the transaction will revert.
    /// @param _data The calldata that encodes the callback to be called on the
    /// `msg.sender`. This is the mechanism through which the borrower is able
    /// to implement their custom keeper logic. The callback will be called from
    /// the KeeperDAO borrow proxy.
    function borrow(
        address _token,
        uint256 _amount,
        bytes calldata _data
    ) external;
}
