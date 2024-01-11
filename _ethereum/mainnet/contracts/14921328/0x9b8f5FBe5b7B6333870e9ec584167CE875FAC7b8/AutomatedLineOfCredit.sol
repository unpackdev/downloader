// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {SafeERC20} from "SafeERC20.sol";
import {IERC20} from "IERC20.sol";

import {IAutomatedLineOfCredit, AutomatedLineOfCreditStatus} from "IAutomatedLineOfCredit.sol";
import {IProtocolConfig} from "IProtocolConfig.sol";
import {BasePortfolio} from "BasePortfolio.sol";

contract AutomatedLineOfCredit is IAutomatedLineOfCredit, BasePortfolio {
    using SafeERC20 for IERC20;

    uint256 internal constant YEAR = 365 days;

    uint256 public maxSize;
    uint256 public borrowedAmount;
    uint256 public accruedInterest;
    address public borrower;
    InterestRateParameters public interestRateParameters;
    uint256 private lastUtilizationUpdateTime;
    uint256 public premiumFee;

    event Borrowed(uint256 amount);

    event Repaid(uint256 amount);

    event MaxSizeChanged(uint256 newMaxSize);

    function initialize(
        IProtocolConfig _protocolConfig,
        uint256 _duration,
        IERC20 _underlyingToken,
        address _borrower,
        uint256 _maxSize,
        InterestRateParameters memory _interestRateParameters,
        address _depositStrategy,
        address _withdrawStrategy,
        address _transferStrategy,
        string memory name,
        string memory symbol
    ) public initializer {
        require(
            _interestRateParameters.minInterestRateUtilizationThreshold <= _interestRateParameters.optimumUtilization &&
                _interestRateParameters.optimumUtilization <= _interestRateParameters.maxInterestRateUtilizationThreshold,
            "AutomatedLineOfCredit: Min. Util. <= Optimum Util. <= Max. Util. constraint not met"
        );
        __BasePortfolio_init(_protocolConfig, _duration, _underlyingToken, _borrower, 0);
        __ERC20_init(name, symbol);
        borrower = _borrower;
        interestRateParameters = _interestRateParameters;
        maxSize = _maxSize;
        premiumFee = _protocolConfig.automatedLineOfCreditPremiumFee();
        _grantRole(DEPOSIT_ROLE, _depositStrategy);
        _grantRole(WITHDRAW_ROLE, _withdrawStrategy);
        _setTransferStrategy(_transferStrategy);
    }

    function borrow(uint256 amount) public whenNotPaused {
        require(msg.sender == borrower, "AutomatedLineOfCredit: Caller is not the borrower");
        require(address(this) != borrower, "AutomatedLineOfCredit: Pool cannot borrow from itself");
        require(block.timestamp < endDate, "AutomatedLineOfCredit: Pool end date has elapsed");
        require(amount <= virtualTokenBalance, "AutomatedLineOfCredit: Amount exceeds pool balance");

        updateAccruedInterest();
        borrowedAmount += amount;
        virtualTokenBalance -= amount;

        underlyingToken.safeTransfer(borrower, amount);

        emit Borrowed(amount);
    }

    function value() public view override returns (uint256) {
        return _value(totalDebt());
    }

    function repay(uint256 amount) public whenNotPaused {
        require(msg.sender == borrower, "AutomatedLineOfCredit: Caller is not the borrower");
        require(msg.sender != address(this), "AutomatedLineOfCredit: Pool cannot repay itself");
        require(borrower != address(this), "AutomatedLineOfCredit: Pool cannot repay itself");

        updateAccruedInterest();

        if (amount > accruedInterest) {
            uint256 repaidPrincipal = amount - accruedInterest;
            accruedInterest = 0;
            borrowedAmount -= repaidPrincipal;
        } else {
            accruedInterest -= amount;
        }

        _repay(amount);
    }

    function repayInFull() external whenNotPaused {
        require(msg.sender == borrower, "AutomatedLineOfCredit: Caller is not the borrower");
        require(msg.sender != address(this), "AutomatedLineOfCredit: Pool cannot repay itself");
        require(borrower != address(this), "AutomatedLineOfCredit: Pool cannot repay itself");
        uint256 _totalDebt = totalDebt();

        borrowedAmount = 0;
        accruedInterest = 0;
        lastUtilizationUpdateTime = 0;

        _repay(_totalDebt);
    }

    function _repay(uint256 amount) internal {
        require(amount > 0, "AutomatedLineOfCredit: Repayment amount must be greater than 0");
        virtualTokenBalance += amount;
        underlyingToken.safeTransferFrom(borrower, address(this), amount);

        emit Repaid(amount);
    }

    /* @notice This contract is upgradeable and interacts with settable deposit strategies,
     * that may change over the contract's lifespan. As a safety measure, we recommend approving
     * this contract with the desired deposit amount instead of performing infinite allowance.
     */
    function deposit(uint256 amount, address sender) public override {
        require(sender != address(this), "AutomatedLineOfCredit: Pool cannot deposit to itself");
        require(block.timestamp < endDate, "AutomatedLineOfCredit: Pool end date has elapsed");
        require((value() + amount) <= maxSize, "AutomatedLineOfCredit: Deposit would cause pool to exceed max size");
        updateAccruedInterest();
        super.deposit(amount, sender);
    }

    function withdraw(uint256 shares, address sender) public override onlyRole(WITHDRAW_ROLE) whenNotPaused {
        require(msg.sender != address(this), "AutomatedLineOfCredit: Pool cannot withdraw from itself");
        require(msg.sender != sender, "AutomatedLineOfCredit: Pool cannot withdraw from itself");
        require(sender != address(this), "AutomatedLineOfCredit: Pool cannot withdraw from itself");

        updateAccruedInterest();

        uint256 _sharesValue = sharesValue(shares);
        require(_sharesValue <= virtualTokenBalance, "AutomatedLineOfCredit: Amount exceeds pool balance");
        virtualTokenBalance -= _sharesValue;
        uint256 feeAmount = calculateFeeAmount(_sharesValue);
        uint256 amountToWithdraw = _sharesValue - feeAmount;

        _burn(sender, shares);

        address protocolAddress = protocolConfig.protocolAddress();
        underlyingToken.safeTransfer(sender, amountToWithdraw);
        underlyingToken.safeTransfer(protocolAddress, feeAmount);

        emit Withdrawn(shares, amountToWithdraw, sender);
        emit FeePaid(sender, protocolAddress, feeAmount);
    }

    function unincludedInterest() public view returns (uint256) {
        return (interestRate() * borrowedAmount * (block.timestamp - lastUtilizationUpdateTime)) / YEAR / BASIS_PRECISION;
    }

    function interestRate() public view returns (uint256) {
        return _interestRate(_utilization(borrowedAmount));
    }

    function _interestRate(uint256 currentUtilization) internal view returns (uint256) {
        (
            uint32 minInterestRate,
            uint32 minInterestRateUtilizationThreshold,
            uint32 optimumInterestRate,
            uint32 optimumUtilization,
            uint32 maxInterestRate,
            uint32 maxInterestRateUtilizationThreshold
        ) = getInterestRateParameters();
        if (currentUtilization <= minInterestRateUtilizationThreshold) {
            return minInterestRate;
        } else if (currentUtilization <= optimumUtilization) {
            return
                solveLinear(
                    currentUtilization,
                    minInterestRateUtilizationThreshold,
                    minInterestRate,
                    optimumUtilization,
                    optimumInterestRate
                );
        } else if (currentUtilization <= maxInterestRateUtilizationThreshold) {
            return
                solveLinear(
                    currentUtilization,
                    optimumUtilization,
                    optimumInterestRate,
                    maxInterestRateUtilizationThreshold,
                    maxInterestRate
                );
        } else {
            return maxInterestRate;
        }
    }

    function setMaxSize(uint256 _maxSize) external onlyRole(MANAGER_ROLE) {
        require(_maxSize != maxSize, "AutomatedLineOfCredit: New max size needs to be different");
        maxSize = _maxSize;
        emit MaxSizeChanged(_maxSize);
    }

    function utilization() external view returns (uint256) {
        return _utilization(borrowedAmount);
    }

    function calculateAmountToWithdraw(uint256 sharesAmount) public view virtual override returns (uint256) {
        return (sharesValue(sharesAmount) * (BASIS_PRECISION - totalFee())) / BASIS_PRECISION;
    }

    function sharesValue(uint256 sharesAmount) public view virtual returns (uint256) {
        return (sharesAmount * value()) / totalSupply();
    }

    function calculateFeeAmount(uint256 _sharesValue) internal view virtual returns (uint256) {
        return (_sharesValue * totalFee()) / BASIS_PRECISION;
    }

    function totalFee() internal view virtual returns (uint256) {
        uint256 _totalFee = protocolConfig.protocolFee() + managerFee + premiumFee;
        return _totalFee < BASIS_PRECISION ? _totalFee : BASIS_PRECISION;
    }

    function totalDebt() public view returns (uint256) {
        return borrowedAmount + accruedInterest + unincludedInterest();
    }

    function solveLinear(
        uint256 x,
        uint256 x1,
        uint256 y1,
        uint256 x2,
        uint256 y2
    ) internal pure returns (uint256) {
        return (y1 * (x2 - x) + y2 * (x - x1)) / (x2 - x1);
    }

    function getInterestRateParameters()
        public
        view
        returns (
            uint32,
            uint32,
            uint32,
            uint32,
            uint32,
            uint32
        )
    {
        InterestRateParameters memory _interestRateParameters = interestRateParameters;
        return (
            _interestRateParameters.minInterestRate,
            _interestRateParameters.minInterestRateUtilizationThreshold,
            _interestRateParameters.optimumInterestRate,
            _interestRateParameters.optimumUtilization,
            _interestRateParameters.maxInterestRate,
            _interestRateParameters.maxInterestRateUtilizationThreshold
        );
    }

    function getStatus() external view returns (AutomatedLineOfCreditStatus) {
        if (block.timestamp >= endDate) {
            return AutomatedLineOfCreditStatus.Closed;
        } else if (value() >= maxSize) {
            return AutomatedLineOfCreditStatus.Full;
        } else {
            return AutomatedLineOfCreditStatus.Open;
        }
    }

    function updateAccruedInterest() internal {
        accruedInterest += unincludedInterest();
        lastUtilizationUpdateTime = block.timestamp;
    }

    function _value(uint256 debt) internal view returns (uint256) {
        return virtualTokenBalance + debt;
    }

    function _utilization(uint256 debt) internal view returns (uint256) {
        if (debt == 0) {
            return 0;
        }
        return (debt * BASIS_PRECISION) / _value(debt);
    }
}
