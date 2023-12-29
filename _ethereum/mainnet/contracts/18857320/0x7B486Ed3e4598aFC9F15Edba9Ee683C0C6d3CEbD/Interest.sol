// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import "./FixedPointMathLib.sol";
import "./IMultiSourceLoan.sol";
import "./IBaseLoan.sol";

library Interest {
    using FixedPointMathLib for uint256;

    uint256 private constant _PRECISION = 10000;

    uint256 private constant _SECONDS_PER_YEAR = 31536000;

    function getInterest(IBaseLoan.LoanOffer memory _loanOffer) internal pure returns (uint256) {
        return _getInterest(_loanOffer.principalAmount, _loanOffer.aprBps, _loanOffer.duration);
    }

    function getInterest(uint256 _amount, uint256 _aprBps, uint256 _duration) internal pure returns (uint256) {
        return _getInterest(_amount, _aprBps, _duration);
    }

    function getTotalOwed(IMultiSourceLoan.Loan memory _loan, uint256 _timestamp) internal pure returns (uint256) {
        uint256 owed = 0;
        for (uint256 i = 0; i < _loan.source.length;) {
            IMultiSourceLoan.Source memory source = _loan.source[i];
            owed += source.principalAmount + source.accruedInterest
                + _getInterest(source.principalAmount, source.aprBps, _timestamp - source.startTime);
            unchecked {
                ++i;
            }
        }
        return owed;
    }

    function _getInterest(uint256 _amount, uint256 _aprBps, uint256 _duration) private pure returns (uint256) {
        return _amount.mulDivUp(_aprBps * _duration, _PRECISION * _SECONDS_PER_YEAR);
    }
}
