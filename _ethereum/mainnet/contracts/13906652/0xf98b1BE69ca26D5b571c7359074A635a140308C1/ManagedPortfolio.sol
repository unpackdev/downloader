// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ERC20Upgradeable} from "ERC20Upgradeable.sol";
import {IERC721Receiver} from "IERC721Receiver.sol";
import {IManagedPortfolio, ManagedPortfolioStatus} from "IManagedPortfolio.sol";
import {IERC20WithDecimals} from "IERC20WithDecimals.sol";
import {IBulletLoans, BulletLoanStatus} from "IBulletLoans.sol";
import {IProtocolConfig} from "IProtocolConfig.sol";
import {ILenderVerifier} from "ILenderVerifier.sol";
import {InitializableManageable} from "InitializableManageable.sol";

contract ManagedPortfolio is ERC20Upgradeable, InitializableManageable, IERC721Receiver, IManagedPortfolio {
    uint256 constant YEAR = 365 days;

    uint256[] _loans;

    IERC20WithDecimals public override underlyingToken;
    IBulletLoans public bulletLoans;
    IProtocolConfig public protocolConfig;
    ILenderVerifier public lenderVerifier;

    uint256 public override endDate;
    uint256 public override maxSize;
    uint256 public totalDeposited;
    uint256 public latestRepaymentDate;
    uint256 public defaultedLoansCount;
    uint256 public override managerFee;

    event Deposited(address indexed lender, uint256 amount);

    event Withdrawn(address indexed lender, uint256 sharesAmount, uint256 receivedAmount);

    event BulletLoanCreated(uint256 id, uint256 loanDuration, address borrower, uint256 principalAmount, uint256 repaymentAmount);

    event BulletLoanDefaulted(uint256 id);

    event ManagerFeeChanged(uint256 newManagerFee);

    event MaxSizeChanged(uint256 newMaxSize);

    event EndDateChanged(uint256 newEndDate);

    event LenderVerifierChanged(ILenderVerifier newLenderVerifier);

    modifier onlyOpened() {
        require(getStatus() == ManagedPortfolioStatus.Open, "ManagedPortfolio: Portfolio is not opened");
        _;
    }

    modifier onlyClosed() {
        require(getStatus() == ManagedPortfolioStatus.Closed, "ManagedPortfolio: Portfolio is not closed");
        _;
    }

    constructor() InitializableManageable(msg.sender) {}

    function initialize(
        string memory _name,
        string memory _symbol,
        address _manager,
        IERC20WithDecimals _underlyingToken,
        IBulletLoans _bulletLoans,
        IProtocolConfig _protocolConfig,
        ILenderVerifier _lenderVerifier,
        uint256 _duration,
        uint256 _maxSize,
        uint256 _managerFee
    ) external override initializer {
        ERC20Upgradeable.__ERC20_init(_name, _symbol);
        InitializableManageable.initialize(_manager);
        underlyingToken = _underlyingToken;
        bulletLoans = _bulletLoans;
        protocolConfig = _protocolConfig;
        lenderVerifier = _lenderVerifier;
        endDate = block.timestamp + _duration;
        maxSize = _maxSize;
        managerFee = _managerFee;
    }

    function deposit(uint256 depositAmount, bytes memory metadata) external override onlyOpened {
        totalDeposited += depositAmount;
        require(totalDeposited <= maxSize, "ManagedPortfolio: Portfolio is full");
        require(block.timestamp < endDate, "ManagedPortfolio: Cannot deposit after portfolio end date");
        require(lenderVerifier.isAllowed(msg.sender, depositAmount, metadata), "ManagedPortfolio: Signature is invalid");

        _mint(msg.sender, getAmountToMint(depositAmount));
        underlyingToken.transferFrom(msg.sender, address(this), depositAmount);

        emit Deposited(msg.sender, depositAmount);
    }

    function withdraw(uint256 sharesAmount, bytes memory) external override onlyClosed returns (uint256) {
        uint256 liquidFunds = underlyingToken.balanceOf(address(this));
        uint256 amountToWithdraw = (sharesAmount * liquidFunds) / totalSupply();
        _burn(msg.sender, sharesAmount);
        underlyingToken.transfer(msg.sender, amountToWithdraw);

        emit Withdrawn(msg.sender, sharesAmount, amountToWithdraw);

        return amountToWithdraw;
    }

    function createBulletLoan(
        uint256 loanDuration,
        address borrower,
        uint256 principalAmount,
        uint256 repaymentAmount
    ) public override onlyManager {
        require(getStatus() != ManagedPortfolioStatus.Closed, "ManagedPortfolio: Cannot create loan when Portfolio is closed");
        require(block.timestamp < endDate, "ManagedPortfolio: Portfolio end date is in the past");
        uint256 repaymentDate = block.timestamp + loanDuration;
        require(repaymentDate <= endDate, "ManagedPortfolio: Loan end date is greater than Portfolio end date");
        if (repaymentDate > latestRepaymentDate) {
            latestRepaymentDate = repaymentDate;
        }
        uint256 protocolFee = protocolConfig.protocolFee();
        uint256 managersPart = (managerFee * principalAmount * loanDuration) / YEAR / 10000;
        uint256 protocolsPart = (protocolFee * principalAmount * loanDuration) / YEAR / 10000;
        underlyingToken.transfer(borrower, principalAmount);
        underlyingToken.transfer(manager, managersPart);
        underlyingToken.transfer(protocolConfig.protocolAddress(), protocolsPart);
        uint256 loanId = bulletLoans.createLoan(underlyingToken, principalAmount, repaymentAmount, loanDuration, borrower);
        _loans.push(loanId);
        emit BulletLoanCreated(loanId, loanDuration, borrower, principalAmount, repaymentAmount);
    }

    function setManagerFee(uint256 _managerFee) external onlyManager {
        managerFee = _managerFee;
        emit ManagerFeeChanged(_managerFee);
    }

    function setLenderVerifier(ILenderVerifier _lenderVerifier) external onlyManager {
        lenderVerifier = _lenderVerifier;
        emit LenderVerifierChanged(_lenderVerifier);
    }

    function setMaxSize(uint256 _maxSize) external onlyManager {
        maxSize = _maxSize;
        emit MaxSizeChanged(_maxSize);
    }

    function setEndDate(uint256 newEndDate) external override onlyManager {
        require(newEndDate < endDate, "ManagedPortfolio: End date can only be decreased");
        require(newEndDate >= latestRepaymentDate, "ManagedPortfolio: End date cannot be less than max loan default date");
        endDate = newEndDate;
        emit EndDateChanged(newEndDate);
    }

    function value() public view override returns (uint256) {
        return liquidValue() + illiquidValue();
    }

    function getStatus() public view returns (ManagedPortfolioStatus) {
        if (block.timestamp > endDate) {
            return ManagedPortfolioStatus.Closed;
        }
        if (defaultedLoansCount > 0) {
            return ManagedPortfolioStatus.Frozen;
        }
        return ManagedPortfolioStatus.Open;
    }

    function getAmountToMint(uint256 amount) public view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            return (amount * 10**decimals()) / (10**underlyingToken.decimals());
        } else {
            return (amount * _totalSupply) / value();
        }
    }

    function getOpenLoanIds() external view returns (uint256[] memory) {
        return _loans;
    }

    function illiquidValue() public view returns (uint256) {
        uint256 _value = 0;
        for (uint256 i = 0; i < _loans.length; i++) {
            (
                ,
                BulletLoanStatus status,
                uint256 principal,
                uint256 totalDebt,
                uint256 amountRepaid,
                uint256 duration,
                uint256 repaymentDate,

            ) = bulletLoans.loans(_loans[i]);
            if (status != BulletLoanStatus.Issued || amountRepaid >= totalDebt) {
                continue;
            }
            if (repaymentDate <= block.timestamp) {
                _value += totalDebt - amountRepaid;
            } else {
                _value +=
                    ((totalDebt - principal) * (block.timestamp + duration - repaymentDate)) /
                    duration +
                    principal -
                    amountRepaid;
            }
        }
        return _value;
    }

    function liquidValue() public view returns (uint256) {
        return underlyingToken.balanceOf(address(this));
    }

    function markLoanAsDefaulted(uint256 instrumentId) external override onlyManager {
        defaultedLoansCount++;
        bulletLoans.markLoanAsDefaulted(instrumentId);
        emit BulletLoanDefaulted(instrumentId);
    }

    function markLoanAsResolved(uint256 instrumentId) external onlyManager {
        defaultedLoansCount--;
        bulletLoans.markLoanAsResolved(instrumentId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal virtual override {
        require(from == address(0) || to == address(0), "ManagedPortfolio: transfer of LP tokens prohibited");
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
