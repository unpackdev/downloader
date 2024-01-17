// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC721Receiver} from "IERC721Receiver.sol";
import {Address} from "Address.sol";
import {SafeERC20} from "SafeERC20.sol";
import {ERC20Upgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable} from "ERC20Upgradeable.sol";

import {AccessControlEnumerableUpgradeable} from "AccessControlEnumerableUpgradeable.sol";
import {IERC165} from "IERC165.sol";
import {IERC20} from "IERC20.sol";

import {IERC20Metadata} from "ERC20.sol";
import {IFlexiblePortfolio} from "IFlexiblePortfolio.sol";
import {IDebtInstrument} from "IDebtInstrument.sol";
import {IERC4626} from "IERC4626.sol";
import {IProtocolConfig} from "IProtocolConfig.sol";
import {IValuationStrategy} from "IValuationStrategy.sol";
import {ITransferController} from "ITransferController.sol";
import {IDepositController} from "IDepositController.sol";
import {IWithdrawController} from "IWithdrawController.sol";
import {IFeeStrategy} from "IFeeStrategy.sol";
import {Upgradeable} from "Upgradeable.sol";

contract FlexiblePortfolio is IFlexiblePortfolio, ERC20Upgradeable, Upgradeable {
    using SafeERC20 for IERC20Metadata;
    using Address for address;

    uint256 internal constant YEAR = 365 days;
    uint256 public constant BASIS_PRECISION = 10000;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant CONTROLLER_ADMIN_ROLE = keccak256("CONTROLLER_ADMIN_ROLE");

    IERC20Metadata public asset;
    uint8 internal _decimals;
    uint256 public endDate;
    uint256 public maxSize;
    IProtocolConfig public protocolConfig;
    mapping(IDebtInstrument => bool) public isInstrumentAllowed;

    address public managerFeeBeneficiary;
    uint256 public virtualTokenBalance;
    uint256 public lastProtocolFeeRate;
    uint256 public lastManagerFeeRate;
    uint256 public unpaidProtocolFee;
    uint256 public unpaidManagerFee;
    uint256 internal lastUpdateTime;
    uint256 internal highestInstrumentEndDate;

    IValuationStrategy public valuationStrategy;
    IDepositController public depositController;
    IWithdrawController public withdrawController;
    ITransferController public transferController;
    IFeeStrategy public feeStrategy;

    mapping(IDebtInstrument => mapping(uint256 => bool)) public isInstrumentAdded;

    event InstrumentAdded(IDebtInstrument indexed instrument, uint256 indexed instrumentId);
    event InstrumentFunded(IDebtInstrument indexed instrument, uint256 indexed instrumentId);
    event InstrumentUpdated(IDebtInstrument indexed instrument);
    event AllowedInstrumentChanged(IDebtInstrument indexed instrument, bool isAllowed);
    event InstrumentRepaid(IDebtInstrument indexed instrument, uint256 indexed instrumentId, uint256 amount);

    event MaxSizeChanged(uint256 newMaxSize);
    event ManagerFeeBeneficiaryChanged(address indexed managerFeeBeneficiary);
    event ValuationStrategyChanged(IValuationStrategy indexed newStrategy);
    event DepositControllerChanged(IDepositController indexed newController);
    event WithdrawControllerChanged(IWithdrawController indexed newController);
    event TransferControllerChanged(ITransferController indexed newController);
    event FeeStrategyChanged(IFeeStrategy indexed newStrategy);

    event FeePaid(address indexed protocolAddress, uint256 amount);

    function initialize(
        IProtocolConfig _protocolConfig,
        uint256 _duration,
        IERC20Metadata _asset,
        address _manager,
        uint256 _maxSize,
        Controllers calldata _controllers,
        IDebtInstrument[] calldata _allowedInstruments,
        ERC20Metadata calldata tokenMetadata
    ) external initializer {
        require(_duration > 0, "FP:Duration can't be 0");
        __Upgradeable_init(_protocolConfig.protocolAdmin(), _protocolConfig.pauserAddress());
        __ERC20_init(tokenMetadata.name, tokenMetadata.symbol);
        _grantRole(MANAGER_ROLE, _manager);
        _grantRole(CONTROLLER_ADMIN_ROLE, _manager);
        _setManagerFeeBeneficiary(_manager);
        protocolConfig = _protocolConfig;
        endDate = block.timestamp + _duration;
        asset = _asset;
        maxSize = _maxSize;
        _decimals = _asset.decimals();
        _setDepositController(_controllers.depositController);
        _setWithdrawController(_controllers.withdrawController);
        _setTransferController(_controllers.transferController);
        _setFeeStrategy(_controllers.feeStrategy);
        valuationStrategy = _controllers.valuationStrategy;

        for (uint256 i; i < _allowedInstruments.length; i++) {
            isInstrumentAllowed[_allowedInstruments[i]] = true;
        }
    }

    // -- ERC20 metadata --
    function decimals() public view virtual override(ERC20Upgradeable, IERC20MetadataUpgradeable) returns (uint8) {
        return _decimals;
    }

    // -- ERC4626 methods --
    function totalAssets() public view override returns (uint256) {
        (uint256 _totalAssets, , ) = getTotalAssetsAndFee();
        return _totalAssets;
    }

    /* @notice This contract is upgradeable and interacts with settable deposit controllers,
     * that may change over the contract's lifespan. As a safety measure, we recommend approving
     * this contract with the desired deposit amount instead of performing infinite allowance.
     */
    function deposit(uint256 assets, address receiver) external override whenNotPaused returns (uint256) {
        (uint256 shares, uint256 depositFee) = depositController.onDeposit(msg.sender, assets, receiver);
        _executeDeposit(receiver, shares, assets, depositFee);
        return shares;
    }

    function mint(uint256 shares, address receiver) external whenNotPaused returns (uint256) {
        (uint256 assets, uint256 mintFee) = depositController.onMint(msg.sender, shares, receiver);
        _executeDeposit(receiver, shares, assets + mintFee, mintFee);
        return assets + mintFee;
    }

    function _executeDeposit(
        address receiver,
        uint256 shares,
        uint256 transferredAssets,
        uint256 actionFee
    ) internal {
        require(receiver != address(this), "FP:Wrong receiver/owner");
        require(block.timestamp < endDate, "FP:End date elapsed");
        require(transferredAssets >= actionFee, "FP:Fee bigger than assets");
        uint256 depositedAssets = transferredAssets - actionFee;
        require(depositedAssets > 0 && shares > 0, "FP:Operation not allowed");
        (uint256 _totalAssets, uint256 protocolFee, uint256 managerFee) = getTotalAssetsAndFee();
        require(depositedAssets + _totalAssets <= maxSize, "FP:Portfolio is full");

        update();
        virtualTokenBalance += transferredAssets;
        _mint(receiver, shares);
        asset.safeTransferFrom(msg.sender, address(this), transferredAssets);
        payAllFees(actionFee, protocolFee, managerFee);
        emit Deposit(msg.sender, receiver, transferredAssets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external whenNotPaused returns (uint256) {
        (uint256 shares, uint256 withdrawFee) = withdrawController.onWithdraw(msg.sender, assets, receiver, owner);
        _executeWithdraw(owner, receiver, shares, assets, withdrawFee);
        return shares;
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external virtual whenNotPaused returns (uint256) {
        (uint256 assets, uint256 redeemFee) = withdrawController.onRedeem(msg.sender, shares, receiver, owner);
        _executeWithdraw(owner, receiver, shares, assets, redeemFee);
        return assets;
    }

    function _executeWithdraw(
        address owner,
        address receiver,
        uint256 shares,
        uint256 assets,
        uint256 actionFee
    ) internal {
        require(receiver != address(this) && owner != address(this), "FP:Wrong receiver/owner");
        require(assets > 0 && shares > 0, "FP:Operation not allowed");
        (uint256 protocolFee, uint256 managerFee) = getFees();
        require(assets + protocolFee + managerFee + actionFee <= virtualTokenBalance, "FP:Not enough liquidity");

        update();
        _burnFrom(owner, msg.sender, shares);
        virtualTokenBalance -= assets;
        asset.safeTransfer(receiver, assets);
        payAllFees(actionFee, protocolFee, managerFee);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    function previewDeposit(uint256 assets) external view returns (uint256) {
        require(block.timestamp < endDate, "FP:End date elapsed");
        return depositController.previewDeposit(assets);
    }

    function previewMint(uint256 shares) external view returns (uint256) {
        require(block.timestamp < endDate, "FP:End date elapsed");
        return depositController.previewMint(shares);
    }

    function previewWithdraw(uint256 assets) public view returns (uint256) {
        return withdrawController.previewWithdraw(assets);
    }

    function previewRedeem(uint256 shares) external view virtual returns (uint256) {
        return withdrawController.previewRedeem(shares);
    }

    function maxDeposit(address receiver) external view returns (uint256) {
        if (paused() || block.timestamp >= endDate) {
            return 0;
        }
        if (totalAssets() >= maxSize) {
            return 0;
        }
        return depositController.maxDeposit(receiver);
    }

    function maxMint(address receiver) external view returns (uint256) {
        if (paused() || block.timestamp >= endDate) {
            return 0;
        }
        if (totalAssets() >= maxSize) {
            return 0;
        }
        return depositController.maxMint(receiver);
    }

    function maxWithdraw(address owner) external view virtual returns (uint256) {
        if (paused()) {
            return 0;
        }
        return withdrawController.maxWithdraw(owner);
    }

    function maxRedeem(address owner) external view returns (uint256) {
        if (paused()) {
            return 0;
        }
        return withdrawController.maxRedeem(owner);
    }

    function convertToAssets(uint256 sharesAmount) public view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            return 0;
        }
        return (sharesAmount * totalAssets()) / _totalSupply;
    }

    function convertToShares(uint256 assets) public view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            return assets;
        } else {
            uint256 _totalAssets = totalAssets();
            require(_totalAssets > 0, "FP:Infinite value");
            return (assets * _totalSupply) / _totalAssets;
        }
    }

    // -- Portfolio methods --
    function allowInstrument(IDebtInstrument instrument, bool isAllowed) external onlyRole(MANAGER_ROLE) {
        isInstrumentAllowed[instrument] = isAllowed;
        emit AllowedInstrumentChanged(instrument, isAllowed);
    }

    function addInstrument(IDebtInstrument instrument, bytes calldata issueInstrumentCalldata)
        external
        onlyRole(MANAGER_ROLE)
        returns (uint256)
    {
        bytes memory result = _executeInstrumentFunctionCall(instrument, instrument.issueInstrumentSelector, issueInstrumentCalldata);
        uint256 instrumentId = abi.decode(result, (uint256));
        require(instrument.asset(instrumentId) == asset, "FP:Token mismatch");
        isInstrumentAdded[instrument][instrumentId] = true;
        emit InstrumentAdded(instrument, instrumentId);

        return instrumentId;
    }

    function _executeInstrumentFunctionCall(
        IDebtInstrument instrument,
        function() external returns (bytes4) functionSelector,
        bytes calldata functionCallData
    ) internal returns (bytes memory) {
        require(isInstrumentAllowed[instrument], "FP:Instrument not allowed");
        require(functionSelector() == bytes4(functionCallData), "FP:Invalid function call");
        return address(instrument).functionCall(functionCallData);
    }

    function fundInstrument(IDebtInstrument instrument, uint256 instrumentId) external onlyRole(MANAGER_ROLE) {
        require(isInstrumentAdded[instrument][instrumentId], "FP:Instrument not added");
        (uint256 protocolFee, uint256 managerFee) = getFees();
        address borrower = instrument.recipient(instrumentId);
        uint256 principalAmount = instrument.principal(instrumentId);
        instrument.start(instrumentId);
        uint256 instrumentEndDate = instrument.endDate(instrumentId);
        require(principalAmount + protocolFee + managerFee <= virtualTokenBalance, "FP:Not enough liquidity");
        require(instrumentEndDate <= endDate, "FP:Instrument has bigger endDate");
        updateHighestInstrumentEndDate(instrumentEndDate);

        update();
        virtualTokenBalance -= principalAmount;
        payAllFees(0, protocolFee, managerFee);

        valuationStrategy.onInstrumentFunded(this, instrument, instrumentId);
        asset.safeTransfer(borrower, principalAmount);
        emit InstrumentFunded(instrument, instrumentId);
    }

    function updateInstrument(IDebtInstrument instrument, bytes calldata updateInstrumentCalldata) external onlyRole(MANAGER_ROLE) {
        _executeInstrumentFunctionCall(instrument, instrument.updateInstrumentSelector, updateInstrumentCalldata);
        emit InstrumentUpdated(instrument);
    }

    function updateHighestInstrumentEndDate(uint256 instrumentEndDate) internal {
        if (instrumentEndDate > highestInstrumentEndDate) {
            highestInstrumentEndDate = instrumentEndDate;
        }
    }

    function cancelInstrument(IDebtInstrument instrument, uint256 instrumentId) external onlyRole(MANAGER_ROLE) {
        instrument.cancel(instrumentId);
        valuationStrategy.onInstrumentUpdated(this, instrument, instrumentId);
    }

    function markInstrumentAsDefaulted(IDebtInstrument instrument, uint256 instrumentId) external onlyRole(MANAGER_ROLE) {
        instrument.markAsDefaulted(instrumentId);
        valuationStrategy.onInstrumentUpdated(this, instrument, instrumentId);
    }

    function repay(
        IDebtInstrument instrument,
        uint256 instrumentId,
        uint256 assets
    ) external whenNotPaused {
        require(assets > 0, "FP:Amount can't be 0");
        require(instrument.recipient(instrumentId) == msg.sender, "FP:Wrong recipient");
        require(isInstrumentAdded[instrument][instrumentId], "FP:Instrument not added");
        (uint256 protocolFee, uint256 managerFee) = getFees();
        instrument.repay(instrumentId, assets);
        valuationStrategy.onInstrumentUpdated(this, instrument, instrumentId);

        update();
        virtualTokenBalance += assets;
        asset.safeTransferFrom(msg.sender, address(this), assets);
        payAllFees(0, protocolFee, managerFee);
        emit InstrumentRepaid(instrument, instrumentId, assets);
    }

    function liquidAssets() public view returns (uint256) {
        (uint256 protocolFee, uint256 managerFee) = getFees();
        uint256 dueFees = protocolFee + managerFee;
        return virtualTokenBalance > dueFees ? virtualTokenBalance - dueFees : 0;
    }

    function updateAndPayFee() external whenNotPaused {
        (uint256 protocolFee, uint256 managerFee) = getFees();
        update();
        payAllFees(0, protocolFee, managerFee);
    }

    function update() internal {
        lastUpdateTime = block.timestamp;
        lastProtocolFeeRate = protocolConfig.protocolFeeRate();
        lastManagerFeeRate = feeStrategy.managerFeeRate();
    }

    function payAllFees(
        uint256 managerActionFee,
        uint256 protocolFee,
        uint256 managerContinuousFee
    ) internal {
        // Caller must have already checked that the action fee is payable.
        // A managerActionFee must always be paid first before any other fee.
        assert(virtualTokenBalance >= managerActionFee);
        virtualTokenBalance -= managerActionFee;
        emit FeePaid(managerFeeBeneficiary, managerActionFee);

        uint256 paidProtocolFee;
        (unpaidProtocolFee, paidProtocolFee) = splitUnpaidAndPaidFee(protocolFee);
        virtualTokenBalance -= paidProtocolFee;
        address protocolTreasury = protocolConfig.protocolTreasury();
        emit FeePaid(protocolTreasury, paidProtocolFee);

        uint256 paidManagerContinuousFee;
        (unpaidManagerFee, paidManagerContinuousFee) = splitUnpaidAndPaidFee(managerContinuousFee);
        virtualTokenBalance -= paidManagerContinuousFee;
        emit FeePaid(managerFeeBeneficiary, paidManagerContinuousFee);

        asset.safeTransfer(protocolTreasury, paidProtocolFee);
        asset.safeTransfer(managerFeeBeneficiary, managerActionFee + paidManagerContinuousFee);
    }

    function splitUnpaidAndPaidFee(uint256 fee) private view returns (uint256, uint256) {
        uint256 unpaidFee;
        uint256 paidFee;
        if (virtualTokenBalance < fee) {
            unpaidFee = fee - virtualTokenBalance;
            paidFee = virtualTokenBalance;
        } else {
            unpaidFee = 0;
            paidFee = fee;
        }
        return (unpaidFee, paidFee);
    }

    function getFees() public view returns (uint256 protocolFee, uint256 managerFee) {
        (, protocolFee, managerFee) = getTotalAssetsAndFee();
        return (protocolFee, managerFee);
    }

    function getTotalAssetsAndFee()
        internal
        view
        returns (
            uint256 _totalAssets,
            uint256 protocolFee,
            uint256 managerFee
        )
    {
        _totalAssets = virtualTokenBalance + valuationStrategy.calculateValue(this);

        uint256 unpaidFees = unpaidProtocolFee + unpaidManagerFee;
        protocolFee = unpaidProtocolFee;
        managerFee = unpaidManagerFee;
        if (_totalAssets <= unpaidFees) {
            return (0, protocolFee, managerFee);
        }
        _totalAssets -= unpaidFees;

        // lastUpdateTime can only be updated to block.timestamp in this contract,
        // so this should always be true (assuming a monotone clock and no reordering).
        assert(block.timestamp >= lastUpdateTime);
        uint256 timeAdjustedTotalAssets = _totalAssets * (block.timestamp - lastUpdateTime);
        uint256 accruedProtocolFee = (timeAdjustedTotalAssets * lastProtocolFeeRate) / YEAR / BASIS_PRECISION;
        uint256 accruedManagerFee = (timeAdjustedTotalAssets * lastManagerFeeRate) / YEAR / BASIS_PRECISION;

        uint256 accruedFees = accruedProtocolFee + accruedManagerFee;
        protocolFee += accruedProtocolFee;
        managerFee += accruedManagerFee;
        if (_totalAssets <= accruedFees) {
            return (0, protocolFee, managerFee);
        }
        _totalAssets -= accruedFees;

        return (_totalAssets, protocolFee, managerFee);
    }

    // -- Setters --
    function setWithdrawController(IWithdrawController _withdrawController) external onlyRole(CONTROLLER_ADMIN_ROLE) {
        require(_withdrawController != withdrawController, "FP:Value has to be different");
        _setWithdrawController(_withdrawController);
    }

    function _setWithdrawController(IWithdrawController _withdrawController) private {
        withdrawController = _withdrawController;
        emit WithdrawControllerChanged(_withdrawController);
    }

    function setDepositController(IDepositController _depositController) external onlyRole(CONTROLLER_ADMIN_ROLE) {
        require(_depositController != depositController, "FP:Value has to be different");
        _setDepositController(_depositController);
    }

    function _setDepositController(IDepositController _depositController) private {
        depositController = _depositController;
        emit DepositControllerChanged(_depositController);
    }

    function setTransferController(ITransferController _transferController) external onlyRole(CONTROLLER_ADMIN_ROLE) {
        require(_transferController != transferController, "FP:Value has to be different");
        _setTransferController(_transferController);
    }

    function _setTransferController(ITransferController _transferController) internal {
        transferController = _transferController;
        emit TransferControllerChanged(_transferController);
    }

    function setFeeStrategy(IFeeStrategy _feeStrategy) external onlyRole(CONTROLLER_ADMIN_ROLE) {
        require(_feeStrategy != feeStrategy, "FP:Value has to be different");
        _setFeeStrategy(_feeStrategy);
    }

    function _setFeeStrategy(IFeeStrategy _feeStrategy) internal {
        feeStrategy = _feeStrategy;
        emit FeeStrategyChanged(_feeStrategy);
    }

    function setValuationStrategy(IValuationStrategy _valuationStrategy) external onlyRole(CONTROLLER_ADMIN_ROLE) {
        require(_valuationStrategy != valuationStrategy, "FP:Value has to be different");
        valuationStrategy = _valuationStrategy;
        emit ValuationStrategyChanged(_valuationStrategy);
    }

    function setMaxSize(uint256 _maxSize) external onlyRole(MANAGER_ROLE) {
        require(_maxSize != maxSize, "FP:Value has to be different");
        maxSize = _maxSize;
        emit MaxSizeChanged(_maxSize);
    }

    function setEndDate(uint256 newEndDate) external onlyRole(MANAGER_ROLE) {
        require(endDate > block.timestamp, "FP:End date elapsed");
        require(
            newEndDate < endDate && newEndDate > highestInstrumentEndDate && newEndDate > block.timestamp,
            "FP:New endDate too big"
        );
        endDate = newEndDate;
    }

    function setManagerFeeBeneficiary(address newManagerFeeBeneficiary) external onlyRole(MANAGER_ROLE) {
        require(managerFeeBeneficiary != newManagerFeeBeneficiary, "FP:Value has to be different");
        _setManagerFeeBeneficiary(newManagerFeeBeneficiary);
    }

    function _setManagerFeeBeneficiary(address newManagerFeeBeneficiary) internal {
        managerFeeBeneficiary = newManagerFeeBeneficiary;
        emit ManagerFeeBeneficiaryChanged(newManagerFeeBeneficiary);
    }

    // -- ERC721 methods --
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // -- EIP165 --
    function supportsInterface(bytes4 interfaceID) public view override(AccessControlEnumerableUpgradeable, IERC165) returns (bool) {
        return
            (interfaceID == type(IERC165).interfaceId ||
                interfaceID == type(IERC20).interfaceId ||
                interfaceID == ERC20Upgradeable.name.selector ||
                interfaceID == ERC20Upgradeable.symbol.selector ||
                interfaceID == ERC20Upgradeable.decimals.selector ||
                interfaceID == type(IERC4626).interfaceId) || super.supportsInterface(interfaceID);
    }

    // -- ERC20 methods --
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal override whenNotPaused {
        super._approve(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override whenNotPaused {
        require(ITransferController(transferController).canTransfer(sender, recipient, amount), "FP:Operation not allowed");
        super._transfer(sender, recipient, amount);
    }

    function _burnFrom(
        address owner,
        address spender,
        uint256 shares
    ) internal {
        if (spender != owner) {
            uint256 allowed = allowance(owner, msg.sender);
            require(allowed >= shares, "ERC20: decreased allowance below zero");
            _approve(owner, msg.sender, allowed - shares);
        }
        _burn(owner, shares);
    }
}
