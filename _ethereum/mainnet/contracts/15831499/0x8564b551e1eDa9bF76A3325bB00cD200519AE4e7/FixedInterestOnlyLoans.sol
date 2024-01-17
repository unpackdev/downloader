// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AccessControlEnumerableUpgradeable} from "AccessControlEnumerableUpgradeable.sol";
import {IERC165Upgradeable} from "IERC165Upgradeable.sol";
import {IERC721Upgradeable} from "IERC721Upgradeable.sol";
import {ERC721Upgradeable} from "ERC721Upgradeable.sol";
import {IERC20Metadata} from "ERC20.sol";
import {Upgradeable} from "Upgradeable.sol";
import {IFixedInterestOnlyLoans, FixedInterestOnlyLoanStatus} from "IFixedInterestOnlyLoans.sol";
import {IProtocolConfig} from "IProtocolConfig.sol";

contract FixedInterestOnlyLoans is ERC721Upgradeable, Upgradeable, IFixedInterestOnlyLoans {
    LoanMetadata[] internal loans;

    event LoanIssued(uint256 indexed instrumentId);
    event LoanStatusChanged(uint256 indexed instrumentId, FixedInterestOnlyLoanStatus newStatus);
    event GracePeriodUpdated(uint256 indexed instrumentId, uint32 newGracePeriod);
    event Repaid(uint256 indexed instrumentId, uint256 amount);
    event Canceled(uint256 indexed instrumentId);

    modifier onlyLoanOwner(uint256 instrumentId) {
        require(msg.sender == ownerOf(instrumentId), "FixedInterestOnlyLoans: Not a loan owner");
        _;
    }

    modifier onlyLoanStatus(uint256 instrumentId, FixedInterestOnlyLoanStatus _status) {
        require(loans[instrumentId].status == _status, "FixedInterestOnlyLoans: Unexpected loan status");
        _;
    }

    function initialize(IProtocolConfig _protocolConfig) external initializer {
        __Upgradeable_init(msg.sender, _protocolConfig.pauserAddress());
        __ERC721_init("FixedInterestOnlyLoans", "FIOL");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165Upgradeable, ERC721Upgradeable, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function principal(uint256 instrumentId) external view returns (uint256) {
        return loans[instrumentId].principal;
    }

    function asset(uint256 instrumentId) external view returns (IERC20Metadata) {
        return loans[instrumentId].asset;
    }

    function recipient(uint256 instrumentId) external view returns (address) {
        return loans[instrumentId].recipient;
    }

    function canBeRepaidAfterDefault(uint256 instrumentId) external view returns (bool) {
        return loans[instrumentId].canBeRepaidAfterDefault;
    }

    function status(uint256 instrumentId) external view returns (FixedInterestOnlyLoanStatus) {
        return loans[instrumentId].status;
    }

    function periodPayment(uint256 instrumentId) external view returns (uint256) {
        return loans[instrumentId].periodPayment;
    }

    function periodCount(uint256 instrumentId) external view returns (uint16) {
        return loans[instrumentId].periodCount;
    }

    function periodDuration(uint256 instrumentId) external view returns (uint32) {
        return loans[instrumentId].periodDuration;
    }

    function endDate(uint256 instrumentId) external view returns (uint256) {
        return loans[instrumentId].endDate;
    }

    function gracePeriod(uint256 instrumentId) external view returns (uint256) {
        return loans[instrumentId].gracePeriod;
    }

    function issueInstrumentSelector() external pure returns (bytes4) {
        return this.issueLoan.selector;
    }

    function updateInstrumentSelector() external pure returns (bytes4) {
        return this.updateInstrument.selector;
    }

    function currentPeriodEndDate(uint256 instrumentId) external view returns (uint40) {
        return loans[instrumentId].currentPeriodEndDate;
    }

    function periodsRepaid(uint256 instrumentId) external view returns (uint256) {
        return loans[instrumentId].periodsRepaid;
    }

    function loanData(uint256 instrumentId) external view returns (LoanMetadata memory) {
        return loans[instrumentId];
    }

    function issueLoan(
        IERC20Metadata _asset,
        uint256 _principal,
        uint16 _periodCount,
        uint256 _periodPayment,
        uint32 _periodDuration,
        address _recipient,
        uint32 _gracePeriod,
        bool _canBeRepaidAfterDefault
    ) public virtual whenNotPaused returns (uint256) {
        require(_recipient != address(0), "FixedInterestOnlyLoans: recipient cannot be the zero address");

        uint32 loanDuration = _periodCount * _periodDuration;
        require(loanDuration > 0, "FixedInterestOnlyLoans: Loan duration must be greater than 0");

        uint256 _totalInterest = _periodCount * _periodPayment;
        require(_totalInterest > 0, "FixedInterestOnlyLoans: Total interest must be greater than 0");

        uint256 id = loans.length;
        loans.push(
            LoanMetadata(
                _principal,
                _periodPayment,
                FixedInterestOnlyLoanStatus.Created,
                _periodCount,
                _periodDuration,
                0, // currentPeriodEndDate
                _recipient,
                _canBeRepaidAfterDefault,
                0, // periodsRepaid
                _gracePeriod,
                0, // endDate,
                _asset
            )
        );

        _safeMint(msg.sender, id);

        emit LoanIssued(id);
        return id;
    }

    function acceptLoan(uint256 instrumentId)
        public
        virtual
        onlyLoanStatus(instrumentId, FixedInterestOnlyLoanStatus.Created)
        whenNotPaused
    {
        require(msg.sender == loans[instrumentId].recipient, "FixedInterestOnlyLoans: Not a borrower");
        _changeLoanStatus(instrumentId, FixedInterestOnlyLoanStatus.Accepted);
    }

    function start(uint256 instrumentId)
        external
        onlyLoanOwner(instrumentId)
        onlyLoanStatus(instrumentId, FixedInterestOnlyLoanStatus.Accepted)
        whenNotPaused
    {
        LoanMetadata storage loan = loans[instrumentId];
        _changeLoanStatus(instrumentId, FixedInterestOnlyLoanStatus.Started);

        uint32 _periodDuration = loan.periodDuration;
        uint40 loanDuration = loan.periodCount * _periodDuration;
        loan.endDate = uint40(block.timestamp) + loanDuration;
        loan.currentPeriodEndDate = uint40(block.timestamp + _periodDuration);
    }

    function _changeLoanStatus(uint256 instrumentId, FixedInterestOnlyLoanStatus _status) private {
        loans[instrumentId].status = _status;
        emit LoanStatusChanged(instrumentId, _status);
    }

    function repay(uint256 instrumentId, uint256 amount)
        public
        virtual
        onlyLoanOwner(instrumentId)
        whenNotPaused
        returns (uint256 principalRepaid, uint256 interestRepaid)
    {
        require(_canBeRepaid(instrumentId), "FixedInterestOnlyLoans: This loan cannot be repaid");
        LoanMetadata storage loan = loans[instrumentId];
        uint16 _periodsRepaid = loan.periodsRepaid;
        uint16 _periodCount = loan.periodCount;

        interestRepaid = loan.periodPayment;
        if (_periodsRepaid == _periodCount - 1) {
            principalRepaid = loan.principal;
            _changeLoanStatus(instrumentId, FixedInterestOnlyLoanStatus.Repaid);
        }
        require(amount == interestRepaid + principalRepaid, "FixedInterestOnlyLoans: Unexpected repayment amount");

        loan.periodsRepaid = _periodsRepaid + 1;
        loan.currentPeriodEndDate += loan.periodDuration;

        emit Repaid(instrumentId, amount);

        return (principalRepaid, interestRepaid);
    }

    function expectedRepaymentAmount(uint256 instrumentId) external view returns (uint256) {
        LoanMetadata storage loan = loans[instrumentId];
        uint256 amount = loan.periodPayment;
        if (loan.periodsRepaid == loan.periodCount - 1) {
            amount += loan.principal;
        }
        return amount;
    }

    function cancel(uint256 instrumentId) external onlyLoanOwner(instrumentId) whenNotPaused {
        FixedInterestOnlyLoanStatus _status = loans[instrumentId].status;
        require(
            _status == FixedInterestOnlyLoanStatus.Created || _status == FixedInterestOnlyLoanStatus.Accepted,
            "FixedInterestOnlyLoans: Unexpected loan status"
        );
        _changeLoanStatus(instrumentId, FixedInterestOnlyLoanStatus.Canceled);
    }

    function markAsDefaulted(uint256 instrumentId)
        external
        onlyLoanOwner(instrumentId)
        onlyLoanStatus(instrumentId, FixedInterestOnlyLoanStatus.Started)
        whenNotPaused
    {
        require(
            loans[instrumentId].currentPeriodEndDate + loans[instrumentId].gracePeriod < block.timestamp,
            "FixedInterestOnlyLoans: This loan cannot be defaulted"
        );
        _changeLoanStatus(instrumentId, FixedInterestOnlyLoanStatus.Defaulted);
    }

    function updateInstrument(uint256 instrumentId, uint32 newGracePeriod)
        external
        onlyLoanOwner(instrumentId)
        onlyLoanStatus(instrumentId, FixedInterestOnlyLoanStatus.Started)
        whenNotPaused
    {
        require(newGracePeriod > loans[instrumentId].gracePeriod, "FixedInterestOnlyLoans: Grace period can only be extended");
        loans[instrumentId].gracePeriod = newGracePeriod;
        emit GracePeriodUpdated(instrumentId, newGracePeriod);
    }

    function _canBeRepaid(uint256 instrumentId) internal view returns (bool) {
        LoanMetadata storage loan = loans[instrumentId];

        if (loan.status == FixedInterestOnlyLoanStatus.Started) {
            return true;
        } else if (loan.status == FixedInterestOnlyLoanStatus.Defaulted && loan.canBeRepaidAfterDefault) {
            return true;
        } else {
            return false;
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenID
    ) internal virtual override whenNotPaused {
        super._transfer(from, to, tokenID);
    }

    function _approve(address to, uint256 tokenID) internal virtual override whenNotPaused {
        super._approve(to, tokenID);
    }
}
