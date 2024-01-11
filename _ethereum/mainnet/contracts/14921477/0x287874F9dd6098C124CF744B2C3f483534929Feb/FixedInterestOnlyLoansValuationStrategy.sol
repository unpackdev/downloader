// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IProtocolConfig} from "IProtocolConfig.sol";
import {IBasePortfolio} from "IBasePortfolio.sol";
import {IDebtInstrument} from "IDebtInstrument.sol";
import {IValuationStrategy} from "IValuationStrategy.sol";
import {IFixedInterestOnlyLoans, FixedInterestOnlyLoanStatus} from "IFixedInterestOnlyLoans.sol";
import {Upgradeable} from "Upgradeable.sol";

contract FixedInterestOnlyLoansValuationStrategy is Upgradeable, IValuationStrategy {
    IFixedInterestOnlyLoans public fixedInterestOnlyLoansAddress;
    address public parentStrategy;

    mapping(IBasePortfolio => uint256[]) public loans;
    mapping(IBasePortfolio => mapping(uint256 => bool)) public isActive;

    modifier onlyPortfolioOrParentStrategy(IBasePortfolio portfolio) {
        require(
            msg.sender == address(portfolio) || msg.sender == parentStrategy,
            "FixedInterestOnlyLoansValuationStrategy: Only portfolio or parent strategy"
        );
        _;
    }

    function initialize(
        IProtocolConfig _protocolConfig,
        IFixedInterestOnlyLoans _fixedInterestOnlyLoansAddress,
        address _parentStrategy
    ) external initializer {
        __Upgradeable_init(msg.sender, _protocolConfig.pauserAddress());
        fixedInterestOnlyLoansAddress = _fixedInterestOnlyLoansAddress;
        parentStrategy = _parentStrategy;
    }

    function onInstrumentFunded(
        IBasePortfolio portfolio,
        IDebtInstrument instrument,
        uint256 instrumentId
    ) external onlyPortfolioOrParentStrategy(portfolio) whenNotPaused {
        require(instrument == fixedInterestOnlyLoansAddress, "FixedInterestOnlyLoansValuationStrategy: Unexpected instrument");
        require(
            !isActive[portfolio][instrumentId],
            "FixedInterestOnlyLoansValuationStrategy: Loan is already active for this portfolio"
        );
        isActive[portfolio][instrumentId] = true;
        loans[portfolio].push(instrumentId);
    }

    function onInstrumentUpdated(
        IBasePortfolio portfolio,
        IDebtInstrument instrument,
        uint256 instrumentId
    ) external onlyPortfolioOrParentStrategy(portfolio) whenNotPaused {
        require(instrument == fixedInterestOnlyLoansAddress, "FixedInterestOnlyLoansValuationStrategy: Unexpected instrument");
        _tryToExcludeLoan(portfolio, instrumentId);
    }

    function _tryToExcludeLoan(IBasePortfolio portfolio, uint256 instrumentId) private {
        IFixedInterestOnlyLoans.LoanMetadata memory loan = fixedInterestOnlyLoansAddress.loanData(instrumentId);

        if (loan.status != FixedInterestOnlyLoanStatus.Started && isActive[portfolio][instrumentId]) {
            uint256[] storage portfolioLoans = loans[portfolio];

            for (uint256 i = 0; i < portfolioLoans.length; i++) {
                if (portfolioLoans[i] == instrumentId) {
                    portfolioLoans[i] = portfolioLoans[portfolioLoans.length - 1];
                    isActive[portfolio][instrumentId] = false;
                    portfolioLoans.pop();
                    break;
                }
            }
        }
    }

    function calculateValue(IBasePortfolio portfolio) external view returns (uint256) {
        uint256[] memory _loans = loans[portfolio];
        uint256 _value = 0;
        for (uint256 i = 0; i < _loans.length; i++) {
            uint256 instrumentId = _loans[i];
            _value += _calculateLoanValue(instrumentId);
        }

        return _value;
    }

    function activeLoans(IBasePortfolio portfolio) external view returns (uint256[] memory) {
        return loans[portfolio];
    }

    function _calculateLoanValue(uint256 instrumentId) internal view returns (uint256) {
        IFixedInterestOnlyLoans.LoanMetadata memory loan = fixedInterestOnlyLoansAddress.loanData(instrumentId);

        uint256 accruedInterest = _calculateAccruedInterest(loan.periodPayment, loan.periodDuration, loan.periodCount, loan.endDate);
        uint256 interestPaidSoFar = loan.periodsRepaid * loan.periodPayment;

        if (loan.principal + accruedInterest <= interestPaidSoFar) {
            return 0;
        } else {
            return loan.principal + accruedInterest - interestPaidSoFar;
        }
    }

    function _calculateAccruedInterest(
        uint256 periodPayment,
        uint256 periodDuration,
        uint256 periodCount,
        uint256 endDate
    ) internal view returns (uint256) {
        uint256 fullInterest = periodPayment * periodCount;
        if (block.timestamp >= endDate) {
            return fullInterest;
        }

        uint256 loanDuration = (periodDuration * periodCount);
        uint256 passed = block.timestamp + loanDuration - endDate;

        return (fullInterest * passed) / loanDuration;
    }
}
