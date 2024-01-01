// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {SafeERC20} from "SafeERC20.sol";
import {AccessControlEnumerableUpgradeable} from "AccessControlEnumerableUpgradeable.sol";

import {IERC20Metadata} from "ERC20.sol";
import {IAutomatedLineOfCredit, AutomatedLineOfCreditStatus} from "IAutomatedLineOfCredit.sol";
import {IERC4626} from "IERC4626.sol";
import {IERC165} from "IERC165.sol";
import {IERC20} from "IERC20.sol";
import {IProtocolConfig} from "IProtocolConfig.sol";
import {IDepositController} from "IDepositController.sol";
import {IWithdrawController} from "IWithdrawController.sol";
import {ITransferController} from "ITransferController.sol";

import {ERC20Upgradeable, IERC20MetadataUpgradeable} from "ERC20Upgradeable.sol";

import {Upgradeable} from "Upgradeable.sol";

contract AutomatedLineOfCredit is IAutomatedLineOfCredit, ERC20Upgradeable, Upgradeable {
    using SafeERC20 for IERC20Metadata;

    uint256 internal constant YEAR = 365 days;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant CONTROLLER_ADMIN_ROLE = keccak256("CONTROLLER_ADMIN_ROLE");
    uint256 public constant BASIS_PRECISION = 10000;

    IERC20Metadata public asset;
    uint8 internal _decimals;
    uint256 public endDate;
    uint256 public maxSize;
    address public borrower;
    IProtocolConfig public protocolConfig;
    InterestRateParameters public interestRateParameters;

    uint256 public virtualTokenBalance;
    uint256 public borrowedAmount;
    uint256 public accruedInterest;
    uint256 public lastProtocolFeeRate;
    uint256 public unpaidFee;
    uint256 internal lastUpdateTime;

    IDepositController public depositController;
    IWithdrawController public withdrawController;
    ITransferController public transferController;

    event DepositControllerChanged(IDepositController indexed newController);
    event WithdrawControllerChanged(IWithdrawController indexed newController);
    event TransferControllerChanged(ITransferController indexed newController);

    event MaxSizeChanged(uint256 newMaxSize);
    event Borrowed(uint256 amount);
    event Repaid(uint256 amount);
    event FeePaid(address indexed protocolAddress, uint256 amount);

    function initialize(
        IProtocolConfig _protocolConfig,
        uint256 _duration,
        IERC20Metadata _asset,
        address _borrower,
        uint256 _maxSize,
        InterestRateParameters calldata _interestRateParameters,
        Controllers calldata controllers,
        string calldata name,
        string calldata symbol
    ) public initializer {
        require(
            _interestRateParameters.minInterestRateUtilizationThreshold <= _interestRateParameters.optimumUtilization &&
                _interestRateParameters.optimumUtilization <= _interestRateParameters.maxInterestRateUtilizationThreshold,
            "AutomatedLineOfCredit: Min. Util. <= Optimum Util. <= Max. Util. constraint not met"
        );
        require(_duration > 0, "AutomatedLineOfCredit: Cannot have zero duration");

        __Upgradeable_init(_protocolConfig.protocolAdmin(), _protocolConfig.pauserAddress());
        _grantRole(MANAGER_ROLE, _borrower);
        _grantRole(CONTROLLER_ADMIN_ROLE, _borrower);
        protocolConfig = _protocolConfig;
        endDate = block.timestamp + _duration;
        asset = _asset;
        __ERC20_init(name, symbol);
        _decimals = _asset.decimals();
        borrower = _borrower;
        interestRateParameters = _interestRateParameters;
        maxSize = _maxSize;
        _setDepositController(controllers.depositController);
        _setWithdrawController(controllers.withdrawController);
        _setTransferController(controllers.transferController);
    }

    // -- ERC20 metadata --
    function decimals() public view virtual override(ERC20Upgradeable, IERC20MetadataUpgradeable) returns (uint8) {
        return _decimals;
    }

    // -- ERC4626 methods --
    function totalAssets() public view returns (uint256) {
        (uint256 assets, ) = getTotalAssetsAndFee();
        return assets;
    }

    /* @notice This contract is upgradeable and interacts with settable deposit controllers,
     * that may change over the contract's lifespan. As a safety measure, we recommend approving
     * this contract with the desired deposit amount instead of performing infinite allowance.
     */
    function deposit(uint256 assets, address receiver) external whenNotPaused returns (uint256) {
        (uint256 shares, ) = depositController.onDeposit(msg.sender, assets, receiver);
        _executeDeposit(receiver, assets, shares);
        return shares;
    }

    function mint(uint256 shares, address receiver) external virtual whenNotPaused returns (uint256) {
        (uint256 assets, ) = depositController.onMint(msg.sender, shares, receiver);
        _executeDeposit(receiver, assets, shares);
        return assets;
    }

    function _executeDeposit(
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal {
        assert(msg.sender != address(this));
        require(receiver != address(this), "AutomatedLineOfCredit: Portfolio cannot be the receiver");
        require(block.timestamp < endDate, "AutomatedLineOfCredit: Portfolio end date has elapsed");
        require(assets > 0 && shares > 0, "AutomatedLineOfCredit: Operation not allowed");
        (uint256 _totalAssets, uint256 fee) = getTotalAssetsAndFee();
        require(_totalAssets + assets <= maxSize, "AutomatedLineOfCredit: Operation would cause portfolio to exceed max size");

        update();
        _mint(receiver, shares);
        virtualTokenBalance += assets;
        asset.safeTransferFrom(msg.sender, address(this), assets);
        payFee(fee);
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external whenNotPaused returns (uint256) {
        (uint256 shares, ) = withdrawController.onWithdraw(msg.sender, assets, receiver, owner);
        _executeWithdraw(owner, receiver, assets, shares);
        return shares;
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external whenNotPaused returns (uint256) {
        (uint256 assets, ) = withdrawController.onRedeem(msg.sender, shares, receiver, owner);
        _executeWithdraw(owner, receiver, assets, shares);
        return assets;
    }

    function _executeWithdraw(
        address owner,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal {
        assert(msg.sender != address(this));
        require(receiver != address(this), "AutomatedLineOfCredit: Portfolio cannot be the receiver");
        require(owner != address(this), "AutomatedLineOfCredit: Portfolio cannot be the owner");
        require(assets > 0 && shares > 0, "AutomatedLineOfCredit: Operation not allowed");
        uint256 fee = getFee();
        require(assets + fee <= virtualTokenBalance, "AutomatedLineOfCredit: Operation exceeds portfolio liquidity");

        update();
        _burnFrom(owner, msg.sender, shares);
        virtualTokenBalance -= assets;
        asset.safeTransfer(receiver, assets);
        payFee(fee);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    function previewDeposit(uint256 assets) external view returns (uint256) {
        require(block.timestamp < endDate, "AutomatedLineOfCredit: Portfolio end date has elapsed");
        return depositController.previewDeposit(assets);
    }

    function previewMint(uint256 shares) external view returns (uint256) {
        require(block.timestamp < endDate, "AutomatedLineOfCredit: Portfolio end date has elapsed");
        return depositController.previewMint(shares);
    }

    function previewWithdraw(uint256 assets) public view returns (uint256) {
        return withdrawController.previewWithdraw(assets);
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return withdrawController.previewRedeem(shares);
    }

    function maxDeposit(address receiver) external view returns (uint256) {
        if (paused() || getStatus() != AutomatedLineOfCreditStatus.Open) {
            return 0;
        }
        if (totalAssets() >= maxSize) {
            return 0;
        }
        return depositController.maxDeposit(receiver);
    }

    function maxMint(address receiver) external view returns (uint256) {
        if (paused() || getStatus() != AutomatedLineOfCreditStatus.Open) {
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
            assert(_totalAssets != 0);
            return (assets * _totalSupply) / _totalAssets;
        }
    }

    // -- Portfolio methods --
    function borrow(uint256 assets) external whenNotPaused {
        assert(borrower != address(this));
        require(msg.sender == borrower, "AutomatedLineOfCredit: Caller is not the borrower");
        require(block.timestamp < endDate, "AutomatedLineOfCredit: Portfolio end date has elapsed");
        require(assets > 0, "AutomatedLineOfCredit: Cannot borrow zero assets");
        uint256 fee = getFee();
        require(assets + fee <= virtualTokenBalance, "AutomatedLineOfCredit: Amount exceeds portfolio balance");

        update();
        borrowedAmount += assets;
        virtualTokenBalance -= assets;
        asset.safeTransfer(borrower, assets);
        payFee(fee);
        emit Borrowed(assets);
    }

    function repay(uint256 assets) public whenNotPaused {
        assert(borrower != address(this));
        require(msg.sender == borrower, "AutomatedLineOfCredit: Caller is not the borrower");
        uint256 fee = getFee();
        update();
        require(assets > 0, "AutomatedLineOfCredit: Repayment amount must be greater than 0");
        require(assets <= borrowedAmount + accruedInterest, "AutomatedLineOfCredit: Amount must be less than total debt");

        if (assets > accruedInterest) {
            borrowedAmount -= (assets - accruedInterest);
            accruedInterest = 0;
        } else {
            accruedInterest -= assets;
        }
        virtualTokenBalance += assets;

        asset.safeTransferFrom(borrower, address(this), assets);
        payFee(fee);
        emit Repaid(assets);
    }

    function repayInFull() external {
        repay(totalDebt());
        assert(totalDebt() == 0);
    }

    function getStatus() public view returns (AutomatedLineOfCreditStatus) {
        if (block.timestamp >= endDate) {
            return AutomatedLineOfCreditStatus.Closed;
        } else if (totalAssets() >= maxSize) {
            return AutomatedLineOfCreditStatus.Full;
        } else {
            return AutomatedLineOfCreditStatus.Open;
        }
    }

    function utilization() public view returns (uint256) {
        if (borrowedAmount == 0) {
            return 0;
        }
        if (virtualTokenBalance <= unpaidFee) {
            return BASIS_PRECISION;
        }
        uint256 nonAccruingAssets = borrowedAmount + virtualTokenBalance - unpaidFee;
        assert(nonAccruingAssets > 0);
        return (borrowedAmount * BASIS_PRECISION) / nonAccruingAssets;
    }

    function liquidAssets() public view returns (uint256) {
        uint256 dueFee = getFee();
        return virtualTokenBalance > dueFee ? virtualTokenBalance - dueFee : 0;
    }

    function totalDebt() public view returns (uint256) {
        return borrowedAmount + accruedInterest + unincludedInterest();
    }

    function unincludedInterest() public view returns (uint256) {
        return (interestRate() * borrowedAmount * (block.timestamp - lastUpdateTime)) / YEAR / BASIS_PRECISION;
    }

    function interestRate() public view returns (uint256) {
        uint256 currentUtilization = utilization();
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

    function updateAndPayFee() external whenNotPaused {
        uint256 fee = getFee();
        update();
        payFee(fee);
    }

    function update() internal {
        lastProtocolFeeRate = protocolConfig.protocolFeeRate();
        accruedInterest += unincludedInterest();
        lastUpdateTime = block.timestamp;
    }

    function payFee(uint256 fee) internal {
        uint256 _virtualTokenBalance = virtualTokenBalance;
        uint256 feeToPay;
        if (_virtualTokenBalance < fee) {
            feeToPay = _virtualTokenBalance;
            unpaidFee = fee - _virtualTokenBalance;
        } else {
            feeToPay = fee;
            unpaidFee = 0;
        }
        address protocolTreasury = protocolConfig.protocolTreasury();
        virtualTokenBalance = _virtualTokenBalance - feeToPay;
        asset.safeTransfer(protocolTreasury, feeToPay);
        emit FeePaid(protocolTreasury, feeToPay);
    }

    function getFee() public view returns (uint256 fee) {
        (, fee) = getTotalAssetsAndFee();
        return fee;
    }

    function getTotalAssetsAndFee() public view returns (uint256, uint256) {
        uint256 _totalAssets = virtualTokenBalance + totalDebt();

        if (_totalAssets <= unpaidFee) {
            return (0, _totalAssets);
        }
        _totalAssets -= unpaidFee;

        // lastUpdateTime can only be updated to block.timestamp in this contract,
        // so this should always be true (assuming a monotone clock and no reordering).
        assert(block.timestamp >= lastUpdateTime);
        uint256 accruedFee = ((block.timestamp - lastUpdateTime) * lastProtocolFeeRate * _totalAssets) / YEAR / BASIS_PRECISION;
        if (_totalAssets <= accruedFee) {
            return (0, unpaidFee + _totalAssets);
        }
        _totalAssets -= accruedFee;

        return (_totalAssets, unpaidFee + accruedFee);
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

    // -- Setters --
    function setWithdrawController(IWithdrawController _withdrawController) external onlyRole(CONTROLLER_ADMIN_ROLE) {
        require(_withdrawController != withdrawController, "AutomatedLineOfCredit: New withdraw controller needs to be different");
        _setWithdrawController(_withdrawController);
    }

    function _setWithdrawController(IWithdrawController _withdrawController) private {
        withdrawController = _withdrawController;
        emit WithdrawControllerChanged(_withdrawController);
    }

    function setDepositController(IDepositController _depositController) external onlyRole(CONTROLLER_ADMIN_ROLE) {
        require(_depositController != depositController, "AutomatedLineOfCredit: New deposit controller needs to be different");
        _setDepositController(_depositController);
    }

    function _setDepositController(IDepositController _depositController) private {
        depositController = _depositController;
        emit DepositControllerChanged(_depositController);
    }

    function setTransferController(ITransferController _transferController) external onlyRole(CONTROLLER_ADMIN_ROLE) {
        require(_transferController != transferController, "AutomatedLineOfCredit: New transfer controller needs to be different");
        _setTransferController(_transferController);
    }

    function _setTransferController(ITransferController _transferController) internal {
        transferController = _transferController;
        emit TransferControllerChanged(_transferController);
    }

    function setMaxSize(uint256 _maxSize) external onlyRole(MANAGER_ROLE) {
        require(_maxSize != maxSize, "AutomatedLineOfCredit: New max size needs to be different");
        maxSize = _maxSize;
        emit MaxSizeChanged(_maxSize);
    }

    // -- EIP165 methods --
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
        require(transferController.canTransfer(sender, recipient, amount), "AutomatedLineOfCredit: This transfer not permitted");
        super._transfer(sender, recipient, amount);
    }

    function _burnFrom(
        address owner,
        address spender,
        uint256 shares
    ) internal {
        if (spender != owner) {
            uint256 allowed = allowance(owner, msg.sender);
            require(allowed >= shares, "AutomatedLineOfCredit: Caller not approved to burn given amount of shares");
            _approve(owner, msg.sender, allowed - shares);
        }
        _burn(owner, shares);
    }
}
