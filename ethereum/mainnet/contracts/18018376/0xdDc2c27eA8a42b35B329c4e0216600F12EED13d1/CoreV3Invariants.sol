// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import "./Strings.sol";
import "./SignedMath.sol";
import "./CoreV3.sol";

contract CoreV3Invariant {
    // Check that exactDepositLiquidityImpl return the same value as exactDepositLiquidityInEquilImpl when r* = 1.
    function testGeneralDeposit(
        uint256 margin,
        int256 amount,
        int256 cash,
        int256 liability,
        int256 ampFactor
    ) public pure {
        int256 expected = CoreV3.exactDepositLiquidityInEquilImpl(amount, cash, liability, ampFactor);
        int256 actual = CoreV3.exactDepositLiquidityImpl(amount, cash, liability, ampFactor, 1 ether);
        require(
            SignedMath.abs(expected - actual) <= margin,
            string(
                abi.encodePacked(
                    'expected: ',
                    Strings.toString(uint256(expected)),
                    ' but got: ',
                    Strings.toString(uint256(actual))
                )
            )
        );
    }

    // This verifies the following invariant:
    //   OldDeposit = NewDeposit * r
    // where OldDeposit is calculated at r* = 1 and NewDeposit is calculated at r* = r.
    function testGeneralDepositWithCoverageRatio(
        uint256 margin,
        int256 amount,
        int256 cash,
        int256 liability,
        int256 ampFactor
    ) public pure {
        int256 coverageRatio = (1 ether * cash) / liability;
        int256 expected = CoreV3.exactDepositLiquidityInEquilImpl(amount, liability, liability, ampFactor);
        int256 actual = (CoreV3.exactDepositLiquidityImpl(amount, cash, liability, ampFactor, coverageRatio) *
            coverageRatio) / 1 ether;
        require(
            SignedMath.abs(expected - actual) <= margin,
            string(
                abi.encodePacked(
                    'expected: ',
                    Strings.toString(uint256(expected)),
                    ' but got: ',
                    Strings.toString(uint256(actual)),
                    ' at coverage ratio: ',
                    Strings.toString(uint256(coverageRatio))
                )
            )
        );
    }

    // Check that withdrawalAmountImpl return the same value as withdrawalAmountInEquilImpl when r* = 1.
    function testGeneralWithdraw(
        uint256 margin,
        int256 amount,
        int256 cash,
        int256 liability,
        int256 ampFactor
    ) public pure {
        int256 expected = CoreV3.withdrawalAmountInEquilImpl(amount, cash, liability, ampFactor);
        int256 actual = CoreV3.withdrawalAmountImpl(amount, cash, liability, ampFactor, 1 ether);
        require(
            SignedMath.abs(expected - actual) <= margin,
            string(
                abi.encodePacked(
                    'expected: ',
                    Strings.toString(uint256(expected)),
                    ' but got: ',
                    Strings.toString(uint256(actual))
                )
            )
        );
    }

    // This verifies the following invariant:
    //   OldWithdrawals = NewWithdrawals / r
    // where OldWithdrawals is calculated at r* = 1 and NewWithdrawals is calculated at r* = r.
    function testGeneralWithdrawWithCoverageRatio(
        uint256 margin,
        int256 amount,
        int256 cash,
        int256 liability,
        int256 ampFactor
    ) public pure {
        int256 coverageRatio = (1 ether * cash) / liability;
        int256 expected = CoreV3.withdrawalAmountInEquilImpl(amount, liability, liability, ampFactor);
        int256 actual = (CoreV3.withdrawalAmountImpl(amount, cash, liability, ampFactor, coverageRatio) * 1 ether) /
            coverageRatio;
        require(
            SignedMath.abs(expected - actual) <= margin,
            string(
                abi.encodePacked(
                    'expected: ',
                    Strings.toString(uint256(expected)),
                    ' but got: ',
                    Strings.toString(uint256(actual)),
                    ' at coverage ratio: ',
                    Strings.toString(uint256(coverageRatio))
                )
            )
        );
    }
}
