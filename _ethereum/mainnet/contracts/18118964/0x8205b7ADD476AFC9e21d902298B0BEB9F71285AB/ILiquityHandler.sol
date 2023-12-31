// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILiquityHandler {
    event BatchProcessed(
        uint256 nonce,
        uint256 amountLUSD,
        uint256 totalSupply,
        uint256 totalTroveDebt,
        uint256 amountETH,
        uint256 closed
    );
    event DisableBorrow(uint256 nonce, uint256 amountLUSD);
    event SetL2HandlerGasFee(uint256 newL2HandlerGasFee);
    event SetL2BridgeEthFee(uint256 newL2BridgeEthFee);
    event SetRelayer(address newRelayer);

    enum TroveAction {
        NONE,
        BORROW,
        REPAY
    }

    /// @notice Liquity actions
    /// @param Borrow swap tokens from ETH to LUSD.
    /// @param Repay swap tokens from LUSD to ETH.
    enum Action {
        Borrow,
        Repay
    }

    /// @notice Liquity actions
    /// @param nonce the batch nonce.
    /// @param amountETH the total amount ETH.
    /// @param amountLUSD the total amount LUSD.
    struct RequestPayload {
        uint256 nonce;
        uint256 amountETH;
        uint256 amountLUSD;
    }

    /// @notice Liquity actions
    /// @param nonce the batch nonce.
    /// @param amountLUSD the total amount LUSD.
    /// @param totalSupply the total tb supplied.
    /// @param totalTroveDebt the total trove debt.
    /// @param amountETH the total amount ETH.
    /// @param closed state if the trove was closed.
    struct ResponsePayload {
        uint256 nonce;
        uint256 amountLUSD;
        uint256 totalSupply;
        uint256 totalTroveDebt;
        uint256 amountETH;
        uint256 closed;
    }
}
