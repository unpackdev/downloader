// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "./Owned.sol";
import "./FixedPointMathLib.sol";
import "./ReentrancyGuard.sol";
import "./SafeTransferLib.sol";
import "./ERC20.sol";

import "./ILiquidationDistributor.sol";
import "./IMultiSourceLoan.sol";
import "./Interest.sol";

/// @title Liquidation Distributor
/// @author Florida St
/// @notice Receives proceeds from a liquidation and distributes them based on tranches.
contract LiquidationDistributor is ILiquidationDistributor, Owned, ReentrancyGuard {
    using FixedPointMathLib for uint256;
    using Interest for uint256;
    using SafeTransferLib for ERC20;

    constructor() Owned(msg.sender) {}

    function distribute(uint256 _proceeds, IMultiSourceLoan.Loan calldata _loan) external {
        address liquidator = msg.sender;

        IMultiSourceLoan.Source memory thisSource;
        uint256 totalPrincipalAndPaidInterestOwed = _loan.principalAmount;
        uint256 totalPendingInterestOwed;
        for (uint256 i = 0; i < _loan.source.length;) {
            thisSource = _loan.source[i];
            totalPrincipalAndPaidInterestOwed += thisSource.accruedInterest;
            totalPendingInterestOwed +=
                thisSource.principalAmount.getInterest(thisSource.aprBps, block.timestamp - thisSource.startTime);
            unchecked {
                ++i;
            }
        }

        if (_proceeds > totalPrincipalAndPaidInterestOwed + totalPendingInterestOwed) {
            uint256 remainder = _proceeds - totalPrincipalAndPaidInterestOwed - totalPendingInterestOwed;
            for (uint256 i = 0; i < _loan.source.length;) {
                thisSource = _loan.source[i];
                /// Total = principal + accruedInterest +  pending + interest + pro-rata remainder
                uint256 total = thisSource.principalAmount + thisSource.accruedInterest
                    + thisSource.principalAmount.getInterest(thisSource.aprBps, block.timestamp - thisSource.startTime)
                    + remainder.mulDivDown(
                        thisSource.principalAmount + thisSource.accruedInterest, totalPrincipalAndPaidInterestOwed
                    );
                ERC20(_loan.principalAddress).safeTransferFrom(address(liquidator), thisSource.lender, total);

                unchecked {
                    ++i;
                }
            }
        } else {
            uint256 remainder = _proceeds;
            for (uint256 i = 0; i < _loan.source.length;) {
                thisSource = _loan.source[i];
                /// Total = pro-rata remainder
                uint256 total = remainder.mulDivDown(
                    thisSource.principalAmount + thisSource.accruedInterest, totalPrincipalAndPaidInterestOwed
                );
                ERC20(_loan.principalAddress).safeTransferFrom(address(liquidator), thisSource.lender, total);

                unchecked {
                    ++i;
                }
            }
        }
    }
}
