// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./IERC165Upgradeable.sol";
import "./IERC20Metadata.sol";
import "./IAccessControl.sol";

import "./TokenTransfersLibrary.sol";
import "./Errors.sol";

import "./TraderBalanceVaultStorage.sol";
import "./Constants.sol";
import "./ITraderBalanceVault.sol";
import "./IWhiteBlackList.sol";
import "./IPausable.sol";

contract TraderBalanceVault is ITraderBalanceVault, TraderBalanceVaultStorage {
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Throws if caller is not granted with _role
     * @param _role The role that is being checked for a function caller
     */
    modifier onlyRole(bytes32 _role) {
        _require(IAccessControl(registry).hasRole(_role, msg.sender), Errors.FORBIDDEN.selector);
        _;
    }

    /**
     * @dev Throws if caller is blacklisted
     */
    modifier notBlackListed() {
        _require(!whiteBlackList.isBlackListed(msg.sender), Errors.SENDER_IS_BLACKLISTED.selector);
        _;
    }

    /**
     * @inheritdoc ITraderBalanceVault
     */
    function initialize(address _registry, address _whiteBlackList) public override initializer {
        _require(
            IERC165Upgradeable(_registry).supportsInterface(type(IAccessControl).interfaceId) &&
                IERC165Upgradeable(_whiteBlackList).supportsInterface(type(IWhiteBlackList).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        registry = _registry;
        whiteBlackList = IWhiteBlackList(_whiteBlackList);
        __Pausable_init();
        __ReentrancyGuard_init();
        __ERC165_init();
    }

    receive() external payable override {
        deposit(NATIVE_CURRENCY, 0);
    }

    /**
     * @inheritdoc ITraderBalanceVault
     */
    function withdraw(address _asset, uint256 _amount) external override nonReentrant notBlackListed {
        _require(_amount != 0, Errors.AMOUNT_IS_0.selector);
        TraderBalance storage traderBalance = balances[msg.sender][_asset];
        _require(_amount <= traderBalance.availableBalance, Errors.INSUFFICIENT_FREE_ASSETS.selector);
        traderBalance.availableBalance -= _amount;
        if (_asset == NATIVE_CURRENCY) {
            TokenTransfersLibrary.doTransferOutETH(msg.sender, _amount);
        } else {
            TokenTransfersLibrary.doTransferOut(_asset, msg.sender, _amount);
        }
        emit Withdraw(msg.sender, _asset, _amount);
    }

    /**
     * @inheritdoc ITraderBalanceVault
     */
    function increaseLockedBalance(
        address _trader,
        address _asset,
        uint256 _amount
    ) external payable override onlyRole(VAULT_ACCESS_ROLE) {
        if (_asset != NATIVE_CURRENCY) {
            _require(
                IERC20Metadata(_asset).decimals() <= MAX_ASSET_DECIMALS,
                Errors.ASSET_DECIMALS_EXCEEDS_MAX_VALUE.selector
            );
        }
        _require(_amount != 0, Errors.AMOUNT_IS_0.selector);
        balances[_trader][_asset].lockedBalance += _amount;

        emit Deposit(_trader, _asset, _amount);
    }

    /**
     * @inheritdoc ITraderBalanceVault
     */
    function useTraderAssets(LockAssetParams calldata _params) external override onlyRole(VAULT_ACCESS_ROLE) {
        TraderBalance storage depositedBalance = balances[_params.trader][_params.depositAsset];
        if (_params.openType != OpenType.OPEN_BY_ORDER) {
            _require(
                _params.depositAmount <= depositedBalance.availableBalance,
                Errors.INSUFFICIENT_FREE_ASSETS.selector
            );
        }
        if (_params.openType == OpenType.OPEN) {
            depositedBalance.availableBalance -= _params.depositAmount;
        } else if (_params.openType == OpenType.OPEN_BY_ORDER) {
            depositedBalance.lockedBalance -= _params.depositAmount;
        } else if (_params.openType == OpenType.CREATE_LIMIT_ORDER) {
            depositedBalance.availableBalance -= _params.depositAmount;
            depositedBalance.lockedBalance += _params.depositAmount;
        }
        if (_params.depositReceiver != address(0)) {
            _require(_params.depositAsset != NATIVE_CURRENCY, Errors.NATIVE_CURRENCY_CANNOT_BE_ASSET.selector);
            TokenTransfersLibrary.doTransferOut(_params.depositAsset, _params.depositReceiver, _params.depositAmount);
        }
    }

    /**
     * @inheritdoc ITraderBalanceVault
     */
    function batchTopUpAvailableBalance(
        BatchTopUpAvailableBalanceParams calldata _params
    ) external override onlyRole(VAULT_ACCESS_ROLE) {
        for (uint256 i; i < _params.length; i++) {
            if (_params.amounts[i] > 0) {
                topUpAvailableBalance(_params.traders[i], _params.asset, _params.amounts[i]);
            }
        }
    }

    /**
     * @inheritdoc ITraderBalanceVault
     */
    function unlockAsset(UnlockAssetParams calldata _params) external override onlyRole(VAULT_ACCESS_ROLE) {
        balances[_params.trader][_params.asset].lockedBalance -= _params.amount;
        balances[_params.receiver][_params.asset].availableBalance += _params.amount;
    }

    /**
     * @inheritdoc ITraderBalanceVault
     */
    function topUpAvailableBalance(
        address receiver,
        address asset,
        uint256 amount
    ) public payable override onlyRole(VAULT_ACCESS_ROLE) {
        _require(asset != address(0) && receiver != address(0), Errors.ADDRESS_NOT_SUPPORTED.selector);
        // >= since we use this function in batchTopUpAvailableBalance
        if (asset == NATIVE_CURRENCY) _require(msg.value >= amount, Errors.INVALID_AMOUNT.selector);
        balances[receiver][asset].availableBalance += amount;
    }

    /**
     * @inheritdoc ITraderBalanceVault
     */
    function withdrawFrom(
        address _from,
        address _to,
        address _asset,
        uint256 _amount,
        bool fromLocked
    ) external override onlyRole(VAULT_ACCESS_ROLE) {
        if (fromLocked) {
            _require(balances[_from][_asset].lockedBalance >= _amount, Errors.INSUFFICIENT_FREE_ASSETS.selector);
            balances[_from][_asset].lockedBalance -= _amount;
        } else {
            _require(balances[_from][_asset].availableBalance >= _amount, Errors.INSUFFICIENT_FREE_ASSETS.selector);
            balances[_from][_asset].availableBalance -= _amount;
        }
        if (_asset == NATIVE_CURRENCY) {
            TokenTransfersLibrary.doTransferOutETH(_to, _amount);
        } else {
            TokenTransfersLibrary.doTransferOut(_asset, _to, _amount);
        }
    }

    /**
     * @inheritdoc IPausable
     */
    function pause() external override onlyRole(EMERGENCY_ADMIN) {
        _pause();
    }

    /**
     * @inheritdoc IPausable
     */
    function unpause() external override onlyRole(SMALL_TIMELOCK_ADMIN) {
        _unpause();
    }

    /**
     * @inheritdoc ITraderBalanceVault
     */
    function deposit(
        address _asset,
        uint256 _amount
    ) public payable override nonReentrant notBlackListed whenNotPaused {
        if (_asset == NATIVE_CURRENCY) {
            _require(msg.value > 0 && _amount == 0, Errors.AMOUNT_IS_0.selector);
            _amount = msg.value;
        } else {
            _require(msg.value == 0 && _amount > 0, Errors.AMOUNT_IS_0.selector);
            _require(
                IERC20Metadata(_asset).decimals() <= MAX_ASSET_DECIMALS,
                Errors.ASSET_DECIMALS_EXCEEDS_MAX_VALUE.selector
            );
            TokenTransfersLibrary.doTransferIn(_asset, msg.sender, _amount);
        }
        balances[msg.sender][_asset].availableBalance += _amount;
        emit Deposit(msg.sender, _asset, _amount);
    }

    /**
     * @notice Interface checker
     * @param _interfaceId The interface id to check
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(_interfaceId) || _interfaceId == type(ITraderBalanceVault).interfaceId;
    }
}
