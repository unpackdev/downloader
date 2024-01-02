// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.17;

import "./IERC4626.sol";
import "./ERC20.sol";
import "./IERC20Metadata.sol";
import "./draft-ERC20Permit.sol";
import "./draft-IERC20Permit.sol";
import "./ERC4626.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./EnumerableMap.sol";
import "./Ownable.sol";
import "./IVault.sol";
import "./IMigratable.sol";
import "./Capped.sol";
import "./Migratable.sol";

/**
 * @title BaseVault
 * @notice A Vault that tokenize shares of strategy
 * @author Pods Finance
 */
abstract contract BaseVault is IVault, ERC20Permit, ERC4626, Ownable, Migratable, Capped {
    using SafeERC20 for IERC20Metadata;
    using Math for uint256;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    /**
     * @dev DENOMINATOR represents the precision for the following system variables:
     * - MAX_WITHDRAW_FEE
     * - INVESTOR_RATIO
     */
    uint256 public constant DENOMINATOR = 10000;
    /**
     * @notice Minimum asset amount for the first deposit
     * @dev This amount that prevents the first depositor to steal funds from subsequent depositors.
     * See https://code4rena.com/reports/2022-01-sherlock/#h-01-first-user-can-steal-everyone-elses-tokens
     */
    uint256 public immutable MIN_INITIAL_ASSETS;
    /**
     * @dev MAX_WITHDRAW_FEE is a safe check in case the ConfigurationManager sets
     * a fee high enough that can be used as a way to drain funds.
     * The precision of this number is set by constant DENOMINATOR.
     */
    uint256 public constant MAX_WITHDRAW_FEE = 1000;

    VaultState internal vaultState;
    EnumerableMap.AddressToUintMap internal depositQueue;
    EnumerableMap.AddressToUintMap internal withdrawQueue;

    constructor(
        IERC20Metadata asset_,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) ERC20Permit(name_) ERC4626(asset_) Migratable() Capped() {
        // Vault starts in `start` state
        emit RoundStarted(vaultState.currentRoundId, 0);
        vaultState.lastEndRoundTimestamp = uint40(block.timestamp);

        MIN_INITIAL_ASSETS = 10 ** uint256(asset_.decimals());
    }

    modifier onlyController() {
        if (msg.sender != controller()) revert IVault__CallerIsNotTheController();
        _;
    }

    modifier onlyRoundStarter() {
        bool lastRoundEndedAWeekAgo = block.timestamp >= vaultState.lastEndRoundTimestamp + 1 weeks;

        if (!lastRoundEndedAWeekAgo && msg.sender != controller()) {
            revert IVault__CallerIsNotTheController();
        }
        _;
    }

    /**
     * @inheritdoc ERC20
     */
    function decimals() public view override(ERC20, ERC4626, IERC20Metadata) returns (uint8) {
        return super.decimals();
    }

    /**
     * @inheritdoc IVault
     */
    function currentRoundId() external view returns (uint32) {
        return vaultState.currentRoundId;
    }

    /**
     * @inheritdoc IVault
     */
    function isProcessingDeposits() external view returns (bool) {
        return vaultState.isProcessingDeposits;
    }

    /**
     * @inheritdoc IVault
     */
    function isExpired() external view returns (bool) {
        return vaultState.isExpired;
    }

    /**
     * @inheritdoc IVault
     */
    function processedDeposits() external view returns (uint256) {
        return vaultState.processedDeposits;
    }

    /**
     * @inheritdoc IERC4626
     */
    function deposit(uint256 assets, address receiver) public virtual override(ERC4626, IERC4626) returns (uint256) {
        _assertIsNotProcessingDeposits();
        return super.deposit(assets, receiver);
    }

    /**
     * @inheritdoc IVault
     */
    function depositWithPermit(
        uint256 assets,
        address receiver,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256) {
        _assertIsNotProcessingDeposits();
        IERC20Permit(asset()).permit(msg.sender, address(this), assets, deadline, v, r, s);
        return super.deposit(assets, receiver);
    }

    /**
     * @inheritdoc IERC4626
     */
    function mint(uint256 shares, address receiver) public virtual override(ERC4626, IERC4626) returns (uint256) {
        _assertIsNotProcessingDeposits();
        return super.mint(shares, receiver);
    }

    /**
     * @inheritdoc IVault
     */
    function mintWithPermit(
        uint256 shares,
        address receiver,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256) {
        _assertIsNotProcessingDeposits();
        uint256 assets = previewMint(shares);
        IERC20Permit(asset()).permit(msg.sender, address(this), assets, deadline, v, r, s);
        return super.mint(shares, receiver);
    }

    /**
     * @inheritdoc IERC4626
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override(ERC4626, IERC4626) returns (uint256 assets) {
        _assertIsNotProcessingDeposits();
        assets = convertToAssets(shares);

        if (assets == 0) revert IVault__ZeroAssets();
        (assets, ) = _withdrawWithFees(msg.sender, receiver, owner, assets, shares);
    }

    /**
     * @inheritdoc IERC4626
     * @dev Because of rounding issues, we did not find a way to return assets including the fees.
     * This is not 100% compliant to ERC4626 specification. You can follow the discussion here:
     * https://ethereum-magicians.org/t/eip-4626-yield-bearing-vault-standard/7900/104
     * This function will withdraw the number of assets asked, minus the fee.
     * Example: If the fee is 10% and 100 assets was the input, this function will withdraw 90 assets.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override(ERC4626, IERC4626) returns (uint256 shares) {
        _assertIsNotProcessingDeposits();
        shares = _convertToShares(assets, Math.Rounding.Up);
        (, shares) = _withdrawWithFees(msg.sender, receiver, owner, assets, shares);
    }

    /**
     * @inheritdoc IVault
     */
    function requestRedeem(uint256 shares, address receiver, address owner) external returns (uint256 assets) {
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        // Derives assets from shares requested
        assets = convertToAssets(shares);

        if (assets == 0) revert IVault__ZeroAssets();

        uint256 maxAssets = _convertToAssets(balanceOf(owner), Math.Rounding.Down);
        if (assets > maxAssets) {
            revert IVault__WithdrawRequestAboveMax(msg.sender, owner, assets, maxAssets);
        }

        (bool found, uint256 withdrawAssets) = withdrawQueue.tryGet(owner);
        if (found) {
            vaultState.pendingWithdrawals -= withdrawAssets;
        }

        // Update the amount of assets of a given owner in the queue
        withdrawQueue.set(owner, assets);
        vaultState.pendingWithdrawals += assets;
        emit WithdrawRequested(vaultState.currentRoundId, msg.sender, owner, assets, shares);
    }

    /**
     * @inheritdoc IVault
     */
    function requestWithdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares) {
        uint256 maxAssets = _convertToAssets(balanceOf(owner), Math.Rounding.Down);
        if (assets > maxAssets) {
            revert IVault__WithdrawRequestAboveMax(msg.sender, owner, assets, maxAssets);
        }

        (bool found, uint256 withdrawAssets) = withdrawQueue.tryGet(owner);
        if (found) {
            vaultState.pendingWithdrawals -= withdrawAssets;
        }

        // Derives shares from assets requested
        shares = _convertToShares(assets, Math.Rounding.Up);

        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        // Update the amount of assets of a given owner in the queue
        withdrawQueue.set(owner, assets);
        vaultState.pendingWithdrawals += assets;
        emit WithdrawRequested(vaultState.currentRoundId, msg.sender, owner, assets, shares);
    }

    /**
     * @inheritdoc IERC4626
     * @dev Because of rounding issues, we did not find a way to return exact shares when including the fees.
     * This is not 100% compliant to ERC4626 specification. You can follow the discussion here:
     * https://ethereum-magicians.org/t/eip-4626-yield-bearing-vault-standard/7900/104
     * This function will return the number of shares necessary to withdraw assets not including fees.
     * This means that you will need to redeem MORE shares to achieve the net assets.
     */
    function previewWithdraw(uint256 assets) public view override(ERC4626, IERC4626) returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Up);
    }

    /**
     * @inheritdoc IERC4626
     */
    function previewRedeem(uint256 shares) public view override(ERC4626, IERC4626) returns (uint256) {
        uint256 assets = _convertToAssets(shares, Math.Rounding.Down);
        return assets - _getFee(assets);
    }

    /**
     * @inheritdoc IERC4626
     */
    function maxDeposit(address) public view virtual override(ERC4626, IERC4626) returns (uint256) {
        if (vaultState.isProcessingDeposits) {
            return 0;
        } else {
            return availableCap();
        }
    }

    /**
     * @inheritdoc IERC4626
     */
    function maxMint(address) public view override(ERC4626, IERC4626) returns (uint256) {
        if (vaultState.isProcessingDeposits) {
            return 0;
        } else {
            return availableCap();
        }
    }

    /**
     * @inheritdoc IERC4626
     */
    function maxWithdraw(address owner) public view override(ERC4626, IERC4626) returns (uint256) {
        if (vaultState.isProcessingDeposits) {
            return 0;
        } else {
            return previewRedeem(balanceOf(owner));
        }
    }

    /**
     * @inheritdoc IERC4626
     */
    function maxRedeem(address owner) public view override(ERC4626, IERC4626) returns (uint256) {
        if (vaultState.isProcessingDeposits) {
            return 0;
        } else {
            return balanceOf(owner);
        }
    }

    /**
     * @inheritdoc IVault
     */
    function getWithdrawFeeRatio() public view override returns (uint256) {
        // Fee is limited to MAX_WITHDRAW_FEE
        return Math.min(vaultState.withdrawFeeRatio, MAX_WITHDRAW_FEE);
    }

    /**
     * @inheritdoc IVault
     */
    function setWithdrawFeeRatio(uint16 newWithdrawFeeRatio) external override onlyController {
        emit WithdrawFeeRatioChanged(newWithdrawFeeRatio);
        vaultState.withdrawFeeRatio = newWithdrawFeeRatio;
    }

    /**
     * @inheritdoc IVault
     */
    function assetsOf(address owner) external view virtual returns (uint256) {
        return
            pendingDepositsOf(owner) +
            pendingWithdrawOf(owner) +
            _convertToAssets(balanceOf(owner), Math.Rounding.Down);
    }

    /**
     * @inheritdoc IVault
     */
    function pendingDepositsOf(address owner) public view virtual returns (uint256) {
        (, uint256 assets) = depositQueue.tryGet(owner);
        return assets;
    }

    /**
     * @inheritdoc IVault
     */
    function pendingWithdrawOf(address owner) public view virtual returns (uint256) {
        (, uint256 assets) = withdrawQueue.tryGet(owner);
        return assets;
    }

    /**
     * @inheritdoc IERC4626
     */
    function totalAssets() public view virtual override(ERC4626, IERC4626) returns (uint256) {
        return IERC20Metadata(asset()).balanceOf(address(this)) - totalPendingDeposits();
    }

    /**
     * @inheritdoc IVault
     */
    function totalPendingDeposits() public view virtual returns (uint256) {
        return vaultState.pendingDeposits;
    }

    /**
     * @inheritdoc IVault
     */
    function totalPendingWithdrawals() public view virtual returns (uint256) {
        return vaultState.pendingWithdrawals;
    }

    /**
     * @inheritdoc IVault
     */
    function depositQueueSize() public view returns (uint256) {
        return depositQueue.length();
    }

    /**
     * @inheritdoc IVault
     */
    function withdrawQueueSize() public view returns (uint256) {
        return withdrawQueue.length();
    }

    /**
     * @inheritdoc IVault
     */
    function queuedDeposits() public view returns (address[] memory addresses) {
        addresses = new address[](depositQueue.length());
        for (uint256 i = 0; i < addresses.length; i++) {
            (address owner, ) = depositQueue.at(i);
            addresses[i] = owner;
        }
        return addresses;
    }

    /**
     * @inheritdoc IVault
     */
    function queuedWithdrawals() public view returns (address[] memory addresses) {
        addresses = new address[](withdrawQueue.length());
        for (uint256 i = 0; i < addresses.length; i++) {
            (address owner, ) = withdrawQueue.at(i);
            addresses[i] = owner;
        }
        return addresses;
    }

    /**
     * @inheritdoc IVault
     */
    function controller() public view returns (address) {
        return owner();
    }

    /**
     * @inheritdoc IVault
     */
    function startRound(bytes calldata data) external virtual onlyRoundStarter returns (uint32) {
        if (!vaultState.isProcessingDeposits) revert IVault__NotProcessingDeposits();

        vaultState.isProcessingDeposits = false;

        _afterRoundStart(data);
        emit RoundStarted(vaultState.currentRoundId, vaultState.processedDeposits);
        vaultState.processedDeposits = 0;

        return vaultState.currentRoundId;
    }

    /**
     * @inheritdoc IVault
     */
    function endRound(bytes calldata data) external virtual onlyController {
        if (vaultState.isProcessingDeposits) revert IVault__AlreadyProcessingDeposits();

        vaultState.isProcessingDeposits = true;
        _afterRoundEnd(data);
        vaultState.lastEndRoundTimestamp = uint40(block.timestamp);

        emit RoundEnded(vaultState.currentRoundId);

        vaultState.currentRoundId += 1;
    }

    /**
     * @inheritdoc IVault
     */
    function disburseWithdrawals(address[] calldata depositors) external virtual onlyController {
        for (uint256 i = 0; i < depositors.length; i++) {
            address owner = depositors[i];
            (bool found, uint256 assets) = withdrawQueue.tryGet(owner);

            if (found && assets > 0) {
                uint256 shares = _convertToShares(assets, Math.Rounding.Up);
                _withdrawWithFees(controller(), owner, owner, assets, shares);
            } else {
                revert IVault__WithdrawNotFound(owner);
            }
        }
    }

    /**
     * @inheritdoc IVault
     */
    function refund() external returns (uint256 assets) {
        (, assets) = depositQueue.tryGet(msg.sender);
        if (assets == 0) revert IVault__ZeroAssets();

        if (depositQueue.remove(msg.sender)) {
            _restoreCap(convertToShares(assets));
            vaultState.pendingDeposits -= assets;
        }

        emit DepositRefunded(msg.sender, vaultState.currentRoundId, assets);
        IERC20Metadata(asset()).safeTransfer(msg.sender, assets);
    }

    /**
     * @inheritdoc IVault
     */
    function migrate() external override {
        IVault destinationVault = IVault(getMigrationDestination());

        if (destinationVault == IVault(address(0))) {
            revert Migratable__MigrationNotAllowed();
        }

        // Temporarily set max withdrawals
        uint256 currentPendingWithdrawals = vaultState.pendingWithdrawals;
        withdrawQueue.set(msg.sender, type(uint256).max); // TODO: Review Withdraw Queue under Migration
        vaultState.pendingWithdrawals = type(uint256).max;

        // Redeem owner assets from this Vault
        uint256 shares = balanceOf(msg.sender);
        uint256 assets = redeem(shares, address(this), msg.sender);

        // Return `pendingWithdrawals` value
        vaultState.pendingWithdrawals = currentPendingWithdrawals;

        // Deposit assets to `newVault`
        IERC20Metadata(asset()).safeIncreaseAllowance(address(destinationVault), assets);
        destinationVault.handleMigration(assets, msg.sender);

        emit Migrated(msg.sender, address(this), address(destinationVault), assets, shares);
    }

    /**
     * @inheritdoc IVault
     */
    function handleMigration(uint256 assets, address receiver) external override returns (uint256) {
        IVault sourceVault = IVault(getMigrationSource());

        if (sourceVault == IVault(address(0))) {
            revert Migratable__MigrationNotAllowed();
        }

        return deposit(assets, receiver);
    }

    /**
     * @inheritdoc IVault
     */
    function processQueuedDeposits(address[] calldata depositors) external {
        if (!vaultState.isProcessingDeposits) revert IVault__NotProcessingDeposits();

        for (uint256 i = 0; i < depositors.length; i++) {
            if (depositQueue.contains(depositors[i])) {
                vaultState.processedDeposits += _processDeposit(depositors[i]);
            }
        }
    }

    /**
     * @inheritdoc Capped
     */
    function setCap(uint256 newCap) external override onlyController {
        _setCap(newCap);
    }

    /**
     * @inheritdoc Migratable
     */
    function enableMigration(address destination) external override(Migratable, IMigratable) onlyController {
        _enableMigration(destination);
    }

    /**
     * @inheritdoc Migratable
     */
    function receiveMigration(address source) external override(Migratable, IMigratable) onlyController {
        _receiveMigration(source);
    }

    /**
     * @inheritdoc Migratable
     */
    function cancelMigration() external override(Migratable, IMigratable) onlyController {
        _cancelMigration();
    }

    /**
     * @inheritdoc IVault
     */
    function setExpiredMode() external onlyController {
        if (vaultState.isExpired) {
            revert IVault__AlreadyInExpiredMode();
        }

        // Calls implementation hook
        _beforeExpire();

        // Clears the withdrawQueue and set vault to expired mode
        for (uint256 i = 0; i < withdrawQueue.length(); i++) {
            (address owner, ) = withdrawQueue.at(i);
            withdrawQueue.remove(owner);
        }
        vaultState.pendingWithdrawals = 0;
        vaultState.isExpired = true;
        emit VaultExpired();
    }

    function setRestartMode() external {
        vaultState.isExpired = false;
    }

    /** Internals **/

    /**
     * @notice Mint new shares, effectively representing user participation in the Vault.
     */
    function _processDeposit(address depositor) internal virtual returns (uint256) {
        uint256 currentAssets = totalAssets();
        uint256 supply = totalSupply();
        uint256 assets = depositQueue.get(depositor);
        uint256 shares = currentAssets == 0 || supply == 0
            ? assets
            : assets.mulDiv(supply, currentAssets, Math.Rounding.Down);

        if (supply == 0 && assets < MIN_INITIAL_ASSETS) {
            revert IVault__AssetsUnderMinimumAmount(assets);
        }

        depositQueue.remove(depositor);
        vaultState.pendingDeposits -= assets;
        _mint(depositor, shares);
        emit DepositProcessed(depositor, vaultState.currentRoundId, assets, shares);

        return assets;
    }

    /**
     * @notice Add a new entry to the deposit to queue
     */
    function _addToDepositQueue(address receiver, uint256 assets) internal {
        (, uint256 previous) = depositQueue.tryGet(receiver);
        vaultState.pendingDeposits += assets;
        depositQueue.set(receiver, previous + assets);
    }

    /**
     * @notice Calculate the fee amount on withdraw.
     */
    function _getFee(uint256 assets) internal view returns (uint256) {
        return assets.mulDiv(getWithdrawFeeRatio(), DENOMINATOR, Math.Rounding.Down);
    }

    /**
     * @notice Reverts if the Vault is in a state of "processing deposits"
     */
    function _assertIsNotProcessingDeposits() internal {
        if (vaultState.isProcessingDeposits) {
            revert IVault__ForbiddenWhileProcessingDeposits();
        }
    }

    /**
     * @dev Pull assets from the caller and add it to the deposit queue.
     * Notice: when the vault is expired deposits are not allowed.
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal virtual override {
        if (vaultState.isExpired) {
            revert IVault__AlreadyInExpiredMode();
        }

        IERC20Metadata(asset()).safeTransferFrom(caller, address(this), assets);

        _spendCap(shares);
        _addToDepositQueue(receiver, assets);
        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Burn shares from the caller and release assets to the receiver
     */
    function _withdrawWithFees(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual returns (uint256 receiverAssets, uint256 receiverShares) {
        // Skips when the controller is withdrawing on behalf of `owner`
        if (caller != controller() && caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        _removeFromWithdrawQueue(owner, assets);
        _burn(owner, shares);
        _restoreCap(shares);

        // Apply custom withdraw logic
        _beforeWithdraw(shares, assets);

        uint256 fee = _getFee(assets);
        receiverAssets = assets - fee;
        receiverShares = shares;

        emit Withdraw(caller, receiver, owner, receiverAssets, shares);
        IERC20Metadata(asset()).safeTransfer(receiver, receiverAssets);

        if (fee > 0) {
            emit FeeCollected(fee);
            IERC20Metadata(asset()).safeTransfer(controller(), fee);
        }
    }

    /**
     * @notice Validates if a withdraw was requested and removes from the withdraw queue.
     *
     * @dev The function tries to get the withdrawal amount associated with the owner from the withdrawal queue.
     * If the withdrawal is valid, it will not proceed and revert with the IVault__WithdrawNotRequested error.
     * If the withdrawal is not valid, the function updates the withdrawal queue by deducting
     * the requested assets from the owner's withdrawable assets.
     *
     * If the vault is in expired mode, this function is skipped
     */
    function _removeFromWithdrawQueue(address owner, uint256 assets) internal {
        // If the vault is expired, request checking is skipped
        if (vaultState.isExpired) return;

        (bool withdrawFound, uint256 withdrawAssets) = withdrawQueue.tryGet(owner);
        bool validWithdraw = withdrawFound && assets <= withdrawAssets;

        if (!validWithdraw) {
            revert IVault__WithdrawNotRequested();
        }

        if (withdrawAssets - assets == 0) {
            withdrawQueue.remove(owner);
        } else {
            withdrawQueue.set(owner, withdrawAssets - assets);
        }

        vaultState.pendingWithdrawals -= assets;
    }

    /** Hooks **/

    /* solhint-disable no-empty-blocks */

    /**
     * @dev This hook should be implemented in the contract implementation.
     * It will trigger after the shares were burned
     */
    function _beforeWithdraw(uint256 shares, uint256 assets) internal virtual {}

    /**
     * @dev This hook should be implemented in the contract implementation.
     * It will trigger after setting isProcessingDeposits to false
     */
    function _afterRoundStart(bytes calldata data) internal virtual {}

    /**
     * @dev This hook should be implemented in the contract implementation.
     * It will trigger after setting isProcessingDeposits to true
     */
    function _afterRoundEnd(bytes calldata data) internal virtual {}

    /**
     * @dev This hook should be implemented in the contract implementation.
     * It will trigger before the controller called setExpireMode
     */
    function _beforeExpire() internal virtual {}

    /* solhint-enable no-empty-blocks */
}
