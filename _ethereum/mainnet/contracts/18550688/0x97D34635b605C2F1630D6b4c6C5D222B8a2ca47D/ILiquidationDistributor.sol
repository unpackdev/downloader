// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "./IMultiSourceLoan.sol";

/// @title Liquidation Distributor
/// @author Florida St
/// @notice Given a liquidation. It distributes proceeds accordingly.
interface ILiquidationDistributor {
    /// @notice Called by the liquidator for accounting purposes.
    /// @param _repayment The highest bid of the auction.
    /// @param _loan The loan object.
    function distribute(uint256 _repayment, IMultiSourceLoan.Loan calldata _loan) external;
}
