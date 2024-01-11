// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "IERC20.sol";
import {IERC721Receiver} from "IERC721Receiver.sol";
import {Address} from "Address.sol";
import {SafeERC20} from "SafeERC20.sol";

import {IFlexiblePortfolio} from "IFlexiblePortfolio.sol";
import {IDebtInstrument} from "IDebtInstrument.sol";
import {IBasePortfolio} from "IBasePortfolio.sol";
import {IProtocolConfig} from "IProtocolConfig.sol";
import {IValuationStrategy} from "IValuationStrategy.sol";
import {ITransferStrategy} from "ITransferStrategy.sol";

import {BasePortfolio} from "BasePortfolio.sol";

contract FlexiblePortfolio is IFlexiblePortfolio, BasePortfolio {
    uint256 private constant PRECISION = 1e30;

    using SafeERC20 for IERC20;
    using Address for address;

    mapping(IDebtInstrument => bool) public isInstrumentAllowed;

    uint256 public maxValue;
    IValuationStrategy public valuationStrategy;

    mapping(IDebtInstrument => mapping(uint256 => bool)) public isInstrumentAdded;

    event InstrumentAdded(IDebtInstrument indexed instrument, uint256 indexed instrumentId);
    event InstrumentFunded(IDebtInstrument indexed instrument, uint256 indexed instrumentId);
    event InstrumentUpdated(IDebtInstrument indexed instrument);
    event AllowedInstrumentChanged(IDebtInstrument indexed instrument, bool isAllowed);
    event ValuationStrategyChanged(IValuationStrategy indexed strategy);
    event InstrumentRepaid(IDebtInstrument indexed instrument, uint256 indexed instrumentId, uint256 amount);
    event ManagerFeeChanged(uint256 newManagerFee);
    event MaxValueChanged(uint256 newMaxValue);

    function initialize(
        IProtocolConfig _protocolConfig,
        uint256 _duration,
        IERC20 _underlyingToken,
        address _manager,
        uint256 _maxValue,
        Strategies calldata _strategies,
        IDebtInstrument[] calldata _allowedInstruments,
        uint256 _managerFee,
        ERC20Metadata calldata tokenMetadata
    ) external initializer {
        __BasePortfolio_init(_protocolConfig, _duration, _underlyingToken, _manager, _managerFee);
        __ERC20_init(tokenMetadata.name, tokenMetadata.symbol);
        maxValue = _maxValue;

        _grantRole(DEPOSIT_ROLE, _strategies.depositStrategy);
        _grantRole(WITHDRAW_ROLE, _strategies.withdrawStrategy);
        _setTransferStrategy(_strategies.transferStrategy);
        valuationStrategy = _strategies.valuationStrategy;

        for (uint256 i; i < _allowedInstruments.length; i++) {
            isInstrumentAllowed[_allowedInstruments[i]] = true;
        }
    }

    function allowInstrument(IDebtInstrument instrument, bool isAllowed) external onlyRole(MANAGER_ROLE) {
        isInstrumentAllowed[instrument] = isAllowed;

        emit AllowedInstrumentChanged(instrument, isAllowed);
    }

    function addInstrument(IDebtInstrument instrument, bytes calldata issueInstrumentCalldata)
        external
        onlyRole(MANAGER_ROLE)
        returns (uint256)
    {
        require(isInstrumentAllowed[instrument], "FlexiblePortfolio: Instrument is not allowed");
        require(instrument.issueInstrumentSelector() == bytes4(issueInstrumentCalldata), "FlexiblePortfolio: Invalid function call");

        bytes memory result = address(instrument).functionCall(issueInstrumentCalldata);

        uint256 instrumentId = abi.decode(result, (uint256));
        require(
            instrument.underlyingToken(instrumentId) == underlyingToken,
            "FlexiblePortfolio: Cannot add instrument with different underlying token"
        );
        isInstrumentAdded[instrument][instrumentId] = true;
        emit InstrumentAdded(instrument, instrumentId);

        return instrumentId;
    }

    function fundInstrument(IDebtInstrument instrument, uint256 instrumentId) public onlyRole(MANAGER_ROLE) {
        require(isInstrumentAdded[instrument][instrumentId], "FlexiblePortfolio: Instrument is not added");
        address borrower = instrument.recipient(instrumentId);
        uint256 principalAmount = instrument.principal(instrumentId);
        require(principalAmount <= virtualTokenBalance, "FlexiblePortfolio: Insufficient funds in portfolio to fund loan");
        instrument.start(instrumentId);
        require(
            instrument.endDate(instrumentId) <= endDate,
            "FlexiblePortfolio: Cannot fund instrument which end date is after portfolio end date"
        );
        valuationStrategy.onInstrumentFunded(this, instrument, instrumentId);
        underlyingToken.safeTransfer(borrower, principalAmount);
        virtualTokenBalance -= principalAmount;
        emit InstrumentFunded(instrument, instrumentId);
    }

    function updateInstrument(IDebtInstrument instrument, bytes calldata updateInstrumentCalldata) external onlyRole(MANAGER_ROLE) {
        require(isInstrumentAllowed[instrument], "FlexiblePortfolio: Instrument is not allowed");
        require(instrument.updateInstrumentSelector() == bytes4(updateInstrumentCalldata), "FlexiblePortfolio: Invalid function call");

        address(instrument).functionCall(updateInstrumentCalldata);
        emit InstrumentUpdated(instrument);
    }

    /* @notice This contract is upgradeable and interacts with settable deposit strategies,
     * that may change over the contract's lifespan. As a safety measure, we recommend approving
     * this contract with the desired deposit amount instead of performing infinite allowance.
     */
    function deposit(uint256 amount, address sender) public override(IBasePortfolio, BasePortfolio) whenNotPaused {
        require(getRoleMemberCount(MANAGER_ROLE) == 1, "FlexiblePortfolio: Portfolio has multiple managers");
        require(amount + value() <= maxValue, "FlexiblePortfolio: Portfolio is full");

        uint256 managersPart = (amount * managerFee) / BASIS_PRECISION;
        uint256 protocolsPart = (amount * protocolConfig.protocolFee()) / BASIS_PRECISION;
        require(protocolsPart + managersPart <= amount, "FlexiblePortfolio: Fee cannot exceed deposited amount");

        uint256 amountToDeposit = amount - managersPart - protocolsPart;
        address protocolAddress = protocolConfig.protocolAddress();
        address manager = getRoleMember(MANAGER_ROLE, 0);

        super.deposit(amountToDeposit, sender);
        underlyingToken.safeTransferFrom(sender, manager, managersPart);
        underlyingToken.safeTransferFrom(sender, protocolAddress, protocolsPart);

        emit FeePaid(sender, manager, managersPart);
        emit FeePaid(sender, protocolAddress, protocolsPart);
    }

    function transfer(address recipient, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transfer(recipient, amount);
    }

    function repay(
        IDebtInstrument instrument,
        uint256 instrumentId,
        uint256 amount
    ) external whenNotPaused {
        require(amount > 0, "FlexiblePortfolio: Repayment amount must be greater than 0");
        require(instrument.recipient(instrumentId) == msg.sender, "FlexiblePortfolio: Not an instrument recipient");
        instrument.repay(instrumentId, amount);
        valuationStrategy.onInstrumentUpdated(this, instrument, instrumentId);

        instrument.underlyingToken(instrumentId).safeTransferFrom(msg.sender, address(this), amount);
        virtualTokenBalance += amount;
        emit InstrumentRepaid(instrument, instrumentId, amount);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function setValuationStrategy(IValuationStrategy _valuationStrategy) external onlyRole(MANAGER_ROLE) {
        require(_valuationStrategy != valuationStrategy, "FlexiblePortfolio: New valuation strategy needs to be different");
        valuationStrategy = _valuationStrategy;
        emit ValuationStrategyChanged(_valuationStrategy);
    }

    function value() public view override(BasePortfolio, IBasePortfolio) returns (uint256) {
        if (address(valuationStrategy) == address(0)) {
            return 0;
        }
        return virtualTokenBalance + valuationStrategy.calculateValue(this);
    }

    function liquidValue() public view returns (uint256) {
        return virtualTokenBalance;
    }

    function setManagerFee(uint256 newManagerFee) external onlyRole(MANAGER_ROLE) {
        require(newManagerFee != managerFee, "FlexiblePortfolio: New manager fee needs to be different");
        managerFee = newManagerFee;
        emit ManagerFeeChanged(newManagerFee);
    }

    function setMaxValue(uint256 _maxValue) external onlyRole(MANAGER_ROLE) {
        require(_maxValue != maxValue, "FlexiblePortfolio: New max value needs to be different");
        maxValue = _maxValue;
        emit MaxValueChanged(_maxValue);
    }

    function cancelInstrument(IDebtInstrument instrument, uint256 instrumentId) external onlyRole(MANAGER_ROLE) {
        instrument.cancel(instrumentId);
        valuationStrategy.onInstrumentUpdated(this, instrument, instrumentId);
    }

    function markInstrumentAsDefaulted(IDebtInstrument instrument, uint256 instrumentId) external onlyRole(MANAGER_ROLE) {
        instrument.markAsDefaulted(instrumentId);
        valuationStrategy.onInstrumentUpdated(this, instrument, instrumentId);
    }
}
