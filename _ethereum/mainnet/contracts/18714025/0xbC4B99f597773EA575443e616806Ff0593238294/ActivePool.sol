// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./SafeERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IActivePool.sol";
import "./IDefaultPool.sol";
import "./ITroveManager.sol";
import "./IWETH.sol";
import "./Errors.sol";

/*
 * The Active Pool holds the ETH & wrapper ETH collateral and USDE debt (but not USDE tokens) for all active troves.
 *
 * When a trove is liquidated, it's collateral and USDE debt are transferred from the Active Pool, to either the
 * Stability Pool, the Default Pool, or both, depending on the liquidation conditions.
 *
 */
contract ActivePool is OwnableUpgradeable, IActivePool {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    string public constant NAME = "ActivePool";

    uint256 public constant DECIMAL_PRECISION = 1e18;

    address public borrowerOperationsAddress;
    address public troveManagerAddress;
    address public troveManagerLiquidationsAddress;
    address public troveManagerRedemptionsAddress;
    address public stabilityPoolAddress;
    address public defaultPoolAddress;
    address public treasuryAddress;
    address public liquidityIncentiveAddress;
    address internal collSurplusPoolAddress;
    IWETH public WETH;
    uint256 internal USDEDebt;

    // --- Contract setters ---

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _troveManagerLiquidationAddress,
        address _troveManagerRedemptionsAddress,
        address _stabilityPoolAddress,
        address _defaultPoolAddress,
        address _treasuryAddress,
        address _liquidityIncentiveAddress,
        address _collSurplusPoolAddress,
        address _wethAddress
    ) external onlyOwner {
        _requireIsContract(_borrowerOperationsAddress);
        _requireIsContract(_troveManagerAddress);
        _requireIsContract(_troveManagerLiquidationAddress);
        _requireIsContract(_troveManagerRedemptionsAddress);
        _requireIsContract(_stabilityPoolAddress);
        _requireIsContract(_defaultPoolAddress);
        _requireIsContract(_treasuryAddress);
        _requireIsContract(_liquidityIncentiveAddress);
        _requireIsContract(_collSurplusPoolAddress);
        _requireIsContract(_wethAddress);

        borrowerOperationsAddress = _borrowerOperationsAddress;
        troveManagerAddress = _troveManagerAddress;
        troveManagerLiquidationsAddress = _troveManagerLiquidationAddress;
        troveManagerRedemptionsAddress = _troveManagerRedemptionsAddress;
        stabilityPoolAddress = _stabilityPoolAddress;
        defaultPoolAddress = _defaultPoolAddress;
        treasuryAddress = _treasuryAddress;
        liquidityIncentiveAddress = _liquidityIncentiveAddress;
        collSurplusPoolAddress = _collSurplusPoolAddress;
        WETH = IWETH(_wethAddress);

        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit TroveManagerLiquidationsAddressChanged(
            _troveManagerLiquidationAddress
        );
        emit TroveManagerRedemptionsAddressChanged(
            _troveManagerRedemptionsAddress
        );
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
        emit TreasuryAddressChanged(_treasuryAddress);
        emit LiquidityIncentiveAddressChanged(_liquidityIncentiveAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
        emit WETHAddressChanged(_wethAddress);
    }

    // --- Getters for public variables. Required by IPool interface ---
    /*
     * Returns all collateral balances in state. Not necessarily the contract's actual balances.
     */
    function getTotalCollateral()
        public
        view
        override
        returns (
            uint256 total,
            address[] memory collaterals,
            uint256[] memory amounts
        )
    {
        collaterals = ITroveManager(troveManagerAddress).getCollateralSupport();
        uint256 collLen = collaterals.length;
        amounts = new uint256[](collLen);
        uint256 i = 0;
        for (; i < collLen; ) {
            amounts[i] = IERC20Upgradeable(collaterals[i]).balanceOf(
                address(this)
            );
            total = total.add(amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    /*
     * Returns the collateralBalance for a given collateral
     *
     * Returns the amount of a given collateral in state. Not necessarily the contract's actual balance.
     */
    function getCollateralAmount(
        address _collateral
    ) external view override returns (uint256) {
        return IERC20Upgradeable(_collateral).balanceOf(address(this));
    }

    // Debt that this pool holds.
    function getUSDEDebt() external view override returns (uint256) {
        return USDEDebt;
    }

    // --- Pool functionality ---
    // Send collateral to `_account`, send ETH if `_account` is user
    // Only called by borrowerOperations, troveManager, or stability pool
    function sendCollateral(
        address _account,
        address[] memory _collaterals,
        uint256[] memory _amounts
    ) external override {
        _requireCallerIsBOorTroveMorSPorTMLorTMR();
        uint256 collLen = _collaterals.length;
        address collateral;
        uint256 amount;
        bool flag = _notNeedsToSwitchWETH(_account);
        bool hasETH;
        uint256 ETHAmount;
        uint256 i = 0;
        for (; i < collLen; ) {
            collateral = _collaterals[i];
            amount = _amounts[i];
            if (amount != 0) {
                if (collateral != address(WETH)) {
                    _sendCollateral(_account, collateral, amount);
                } else {
                    hasETH = true;
                    ETHAmount = amount;
                }
            }
            unchecked {
                ++i;
            }
        }
        if (hasETH) {
            if (flag) {
                _sendCollateral(_account, address(WETH), ETHAmount);
            } else {
                _sendETH(_account, ETHAmount);
            }
        }
    }

    function sendCollFees(
        address[] memory _collaterals,
        uint256[] memory _amounts
    ) external override {
        _requireCallerIsBOorTroveMorSPorTMLorTMR();
        uint256 collLen = _collaterals.length;
        address collateral;
        uint256 amount;
        uint256 i = 0;
        for (; i < collLen; ) {
            collateral = _collaterals[i];
            amount = _amounts[i];
            if (amount != 0) {
                uint256 liquidityIncentiveFee = amount
                    .mul(ITroveManager(troveManagerAddress).getFactor())
                    .div(DECIMAL_PRECISION);

                _sendCollateral(
                    liquidityIncentiveAddress,
                    collateral,
                    liquidityIncentiveFee
                );

                _sendCollateral(
                    treasuryAddress,
                    collateral,
                    amount.sub(liquidityIncentiveFee)
                );
            }
            unchecked {
                ++i;
            }
        }
    }

    // Withdraw ETH from WETH and send to user
    function _sendETH(address _to, uint256 _amount) internal {
        address collateral = address(WETH);
        uint256 amount = _amount;
        WETH.withdraw(amount);
        (bool success, ) = _to.call{value: amount}("");
        if (!success) {
            revert Errors.SendETHFailed();
        }
        emit ActivePoolCollBalanceUpdated(
            collateral,
            IERC20Upgradeable(collateral).balanceOf(address(this))
        );
        emit CollateralSent(_to, collateral, amount);
    }

    // Send wrapper ETH to `_to`(different pol)
    function _sendCollateral(
        address _to,
        address _collateral,
        uint256 _amount
    ) internal {
        IERC20Upgradeable(_collateral).safeTransfer(_to, _amount);
        uint256 balance = IERC20Upgradeable(_collateral).balanceOf(
            address(this)
        );
        if (balance == 0) {
            revert Errors.ZeroValue();
        }
        emit ActivePoolCollBalanceUpdated(_collateral, balance);
        emit CollateralSent(_to, _collateral, _amount);
    }

    function _notNeedsToSwitchWETH(
        address _contractAddress
    ) internal view returns (bool) {
        return ((_contractAddress == defaultPoolAddress) ||
            (_contractAddress == stabilityPoolAddress) ||
            (_contractAddress == treasuryAddress) ||
            (_contractAddress == liquidityIncentiveAddress) ||
            (_contractAddress == collSurplusPoolAddress));
    }

    // Record USDE Debt of this pool
    function increaseUSDEDebt(uint256 _amount) external override {
        _requireCallerIsBOorTroveM();
        USDEDebt = USDEDebt.add(_amount);
        emit ActivePoolUSDEDebtUpdated(USDEDebt);
    }

    function decreaseUSDEDebt(uint256 _amount) external override {
        _requireCallerIsBOorTroveMorSPorTMLorTMR();
        uint256 amount = _amount < USDEDebt ? _amount : USDEDebt;
        USDEDebt = USDEDebt.sub(amount);
        emit ActivePoolUSDEDebtUpdated(USDEDebt);
    }

    // --- 'require' functions ---

    function _requireIsContract(address _contract) internal view {
        if (!_contract.isContract()) {
            revert Errors.NotContract();
        }
    }

    function _requireCallerIsBOorTroveMorSPorTMLorTMR() internal view {
        if (
            msg.sender != borrowerOperationsAddress &&
            msg.sender != troveManagerAddress &&
            msg.sender != stabilityPoolAddress &&
            msg.sender != troveManagerRedemptionsAddress &&
            msg.sender != troveManagerLiquidationsAddress
        ) {
            revert Errors.Caller_NotBOOrTMOrSPOrTMLOrTMR();
        }
    }

    function _requireCallerIsBOorTroveM() internal view {
        if (
            msg.sender != borrowerOperationsAddress &&
            msg.sender != troveManagerAddress
        ) {
            revert Errors.Caller_NotBOOrTM();
        }
    }

    // --- Fallback function ---

    receive() external payable {}
}
