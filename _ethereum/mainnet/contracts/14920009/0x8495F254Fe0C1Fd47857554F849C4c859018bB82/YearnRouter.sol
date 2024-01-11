// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import "IERC20.sol";
import "SafeERC20.sol";
import "Math.sol";
import "OwnableUpgradeable.sol";

import "YearnAPI.sol";

/**
 * Adapted from the Yearn BaseRouter that forwards native vault tokens
 * to the caller and does not hold any funds or assets (vault tokens or other ERC20 tokens)
 */
contract YearnRouter is OwnableUpgradeable {
    RegistryAPI public registry;

    // ERC20 Unlimited Approvals (short-circuits VaultAPI.transferFrom)
    uint256 constant UNLIMITED_APPROVAL = type(uint256).max;

    // Sentinel values used to save gas on deposit/withdraw/migrate
    // NOTE: UNLIMITED_APPROVAL == DEPOSIT_EVERYTHING == WITHDRAW_EVERYTHING == MIGRATE_EVERYTHING = MAX_VAULT_ID
    uint256 constant DEPOSIT_EVERYTHING = type(uint256).max;
    uint256 constant WITHDRAW_EVERYTHING = type(uint256).max;
    uint256 constant MIGRATE_EVERYTHING = type(uint256).max;
    uint256 constant MAX_VAULT_ID = type(uint256).max;

    event Deposit(
        address recipient,
        address vault,
        uint256 shares,
        uint256 amount
    );
    event Withdraw(
        address recipient,
        address vault,
        uint256 shares,
        uint256 amount
    );

    function initialize(address yearnRegistry) public initializer {
        __Ownable_init();

        // Recommended to use `v2.registry.ychad.eth`
        registry = RegistryAPI(yearnRegistry);
    }

    /**
     * @notice Used to update the yearn registry. The choice of registry is SECURITY SENSITIVE, so only the
     * owner can update it.
     * @param yearnRegistry The new registry address.
     */
    function setRegistry(address yearnRegistry) external onlyOwner {
        address currentYearnGovernanceAddress = registry.governance();
        // In case you want to override the registry instead of re-deploying
        registry = RegistryAPI(yearnRegistry);
        // Make sure there's no change in governance
        // NOTE: Also avoid bricking the router from setting a bad registry
        require(
            currentYearnGovernanceAddress == registry.governance(),
            "invalid registry"
        );
    }

    function numVaults(address token) external view returns (uint256) {
        return registry.numVaults(token);
    }

    function vaults(address token, uint256 deploymentId)
        external
        view
        returns (VaultAPI)
    {
        return registry.vaults(token, deploymentId);
    }

    function latestVault(address token) external view returns (VaultAPI) {
        return registry.latestVault(token);
    }

    /**
     * @notice Gets the balance of an account across all the vaults for a token.
     * @param token Which ERC20 token to pull vault balances for
     * @param account The address of the account to pull the balances for
     * @return The current value, in token base units, of the shares held by the specified
       account across all the vaults for the specified token.
     */
    function totalVaultBalance(address token, address account)
        external
        view
        returns (uint256)
    {
        return this.totalVaultBalance(token, account, 0, MAX_VAULT_ID);
    }

    /**
     * @notice Gets the balance of an account across certain vaults for a token.
     * @param token Which ERC20 token to pull vault balances for
     * @param account The address of the account to pull the balances for
     * @param firstVaultId First vault id to include; 0 to start at the beginning
     * @param lastVaultId Last vault id to include; `MAX_VAULT_ID` to include all vaults
     * @return balance The current value, in token base units, of the shares held by the specified
       account across all the specified vaults for the specified token.
     */
    function totalVaultBalance(
        address token,
        address account,
        uint256 firstVaultId,
        uint256 lastVaultId
    ) external view returns (uint256 balance) {
        require(firstVaultId <= lastVaultId);

        uint256 _lastVaultId = lastVaultId;
        if (_lastVaultId == MAX_VAULT_ID)
            _lastVaultId = registry.numVaults(address(token)) - 1;

        for (uint256 i = firstVaultId; i <= _lastVaultId; i++) {
            VaultAPI vault = registry.vaults(token, i);
            uint256 vaultTokenBalance = (vault.balanceOf(account) *
                vault.pricePerShare()) / 10**vault.decimals();
            balance += vaultTokenBalance;
        }
    }

    /**
     * @notice Returns the combined TVL for all the vaults for a specified token.
     * @return assets The sum of all the assets managed by the vaults for the specified token.
     */
    function totalAssets(address token) external view returns (uint256) {
        return this.totalAssets(token, 0, MAX_VAULT_ID);
    }

    /**
     * @notice Returns the combined TVL for all the specified vaults for a specified token.
     * @param firstVaultId First vault id to include; 0 to start at the beginning
     * @param lastVaultId Last vault id to include; `MAX_VAULT_ID` to include all vaults
     * @return assets The sum of all the assets managed by the vaults for the specified token.
     */
    function totalAssets(
        address token,
        uint256 firstVaultId,
        uint256 lastVaultId
    ) external view returns (uint256 assets) {
        require(firstVaultId <= lastVaultId);

        uint256 _lastVaultId = lastVaultId;
        if (_lastVaultId == MAX_VAULT_ID)
            _lastVaultId = registry.numVaults(address(token)) - 1;

        for (uint256 i = firstVaultId; i <= _lastVaultId; i++) {
            VaultAPI vault = registry.vaults(token, i);
            assets += vault.totalAssets();
        }
    }

    function getVaultId(address token, address vault)
        external
        view
        returns (uint256)
    {
        uint256 _numVaults = registry.numVaults(token);
        uint256 vaultId = _numVaults;
        for (uint256 i = 0; i < _numVaults; i++) {
            VaultAPI _vault = registry.vaults(token, i);
            if (address(_vault) == vault) {
                vaultId = i;
                break;
            }
        }
        require(vaultId < _numVaults, "vault not registered");
        return vaultId;
    }

    /**
     * @notice Called to deposit the caller's tokens into the most-current vault, crediting the minted shares to recipient.
     * @dev The caller must approve this contract to utilize the specified ERC20 or this call will revert.
     * @param token Address of the ERC20 token being deposited
     * @param recipient Address to receive the issued vault tokens
     * @param amount Amount of tokens to deposit; tokens that cannot be deposited will be refunded. If `DEPOSIT_EVERYTHING`, just deposit everything.
     * @return Total vault shares received by recipient
     */
    function deposit(
        address token,
        address recipient,
        uint256 amount
    ) external returns (uint256) {
        return
            _deposit(
                IERC20(token),
                _msgSender(),
                recipient,
                amount,
                MAX_VAULT_ID
            );
    }

    /**
     * @notice Called to deposit the caller's tokens into a specific vault, crediting the minted shares to recipient.
     * @dev The caller must approve this contract to utilize the specified ERC20 or this call will revert.
     * @param token Address of the ERC20 token being deposited
     * @param recipient Address to receive the issued vault tokens
     * @param amount Amount of tokens to deposit; tokens that cannot be deposited will be refunded. If `DEPOSIT_EVERYTHING`, just deposit everything.
     * @param vaultId Vault id to deposit into; pass `MAX_VAULT_ID` to deposit into the latest vault
     * @return Total vault shares received by recipient
     */
    function deposit(
        address token,
        address recipient,
        uint256 amount,
        uint256 vaultId
    ) external returns (uint256) {
        return
            _deposit(IERC20(token), _msgSender(), recipient, amount, vaultId);
    }

    /**
     * @notice Called to deposit depositor's tokens into a specific vault, crediting the minted shares to recipient.
     * @dev Depositor must approve this contract to utilize the specified ERC20 or this call will revert.
     * @param token Address of the ERC20 token being deposited
     * @param depositor Address to pull deposited funds from. SECURITY SENSITIVE.
     * @param recipient Address to receive the issued vault tokens
     * @param amount Amount of tokens to deposit; tokens that cannot be deposited will be refunded. If `DEPOSIT_EVERYTHING`, just deposit everything.
     * @param vaultId Vault id to deposit into; pass `MAX_VAULT_ID` to deposit into the latest vault
     * @return shares Total vault shares received by recipient
     */
    function _deposit(
        IERC20 token,
        address depositor,
        address recipient,
        uint256 amount,
        uint256 vaultId
    ) internal returns (uint256 shares) {
        bool pullFunds = depositor != address(this);

        VaultAPI vault;
        if (vaultId == MAX_VAULT_ID) {
            vault = registry.latestVault(address(token));
        } else {
            vault = registry.vaults(address(token), vaultId);
        }

        if (token.allowance(address(this), address(vault)) < amount) {
            SafeERC20.safeApprove(token, address(vault), 0); // Avoid issues with some tokens requiring 0
            SafeERC20.safeApprove(token, address(vault), UNLIMITED_APPROVAL); // Vaults are trusted
        }

        uint256 depositorBeforeBal = token.balanceOf(depositor);

        if (amount == DEPOSIT_EVERYTHING) amount = depositorBeforeBal;

        if (pullFunds) {
            uint256 routerBeforeBal = token.balanceOf(address(this));
            SafeERC20.safeTransferFrom(token, depositor, address(this), amount);

            shares = vault.deposit(amount, recipient);

            uint256 routerAfterBal = token.balanceOf(address(this));
            if (routerAfterBal > routerBeforeBal)
                SafeERC20.safeTransfer(
                    token,
                    depositor,
                    routerAfterBal - routerBeforeBal
                );
        } else {
            shares = vault.deposit(amount, recipient);
        }
        uint256 depositorAfterBal = token.balanceOf(depositor);
        uint256 depositedAmount = depositorBeforeBal - depositorAfterBal;
        emit Deposit(recipient, address(vault), shares, depositedAmount);
    }

    /**
     * @notice Called to redeem the all of the caller's shares from underlying vault(s), with the proceeds distributed to recipient.
     * @dev The caller must approve this contract to use their vault shares or this call will revert.
     * @param token Address of the ERC20 token to withdraw from vaults
     * @param recipient Address to receive the withdrawn tokens
     * @return The number of tokens received by recipient.
     */
    function withdraw(address token, address recipient)
        external
        returns (uint256)
    {
        return
            _withdraw(
                IERC20(token),
                _msgSender(),
                recipient,
                WITHDRAW_EVERYTHING,
                0,
                MAX_VAULT_ID
            );
    }

    /**
     * @notice Called to redeem the caller's shares from underlying vault(s), with the proceeds distributed to recipient.
     * @dev The caller must approve this contract to use their vault shares or this call will revert.
     * @param token Address of the ERC20 token to withdraw from vaults
     * @param recipient Address to receive the withdrawn tokens
     * @param amount Maximum number of tokens to withdraw from all vaults; actual withdrawal may be less. If `WITHDRAW_EVERYTHING`, just withdraw everything.
     * @return The number of tokens received by recipient.
     */
    function withdraw(
        address token,
        address recipient,
        uint256 amount
    ) external returns (uint256) {
        return
            _withdraw(
                IERC20(token),
                _msgSender(),
                recipient,
                amount,
                0,
                MAX_VAULT_ID
            );
    }

    /**
     * @notice Called to redeem the caller's shares from underlying vault(s), with the proceeds distributed to recipient.
     * @dev The caller must approve this contract to use their vault shares or this call will revert.
     * @param token Address of the ERC20 token to withdraw from vaults
     * @param recipient Address to receive the withdrawn tokens
     * @param amount Maximum number of tokens to withdraw from all vaults; actual withdrawal may be less. If `WITHDRAW_EVERYTHING`, just withdraw everything.
     * @param firstVaultId First vault id to pull from; 0 to start at the the beginning
     * @param lastVaultId Last vault id to pull from; `MAX_VAULT_ID` to withdraw from all vaults
     * @return The number of tokens received by recipient.
     */
    function withdraw(
        address token,
        address recipient,
        uint256 amount,
        uint256 firstVaultId,
        uint256 lastVaultId
    ) external returns (uint256) {
        return
            _withdraw(
                IERC20(token),
                _msgSender(),
                recipient,
                amount,
                firstVaultId,
                lastVaultId
            );
    }

    /**
     * @notice Called to redeem withdrawer's shares from underlying vault(s), with the proceeds distributed to recipient.
     * @dev Withdrawer must approve this contract to use their vault shares or this call will revert.
     * @param token Address of the ERC20 token to withdraw from vaults
     * @param withdrawer Address to pull the vault shares from. SECURITY SENSITIVE.
     * @param recipient Address to receive the withdrawn tokens
     * @param amount Maximum number of tokens to withdraw from all vaults; actual withdrawal may be less. If `WITHDRAW_EVERYTHING`, just withdraw everything.
     * @param firstVaultId First vault id to pull from; 0 to start at the the beginning
     * @param lastVaultId Last vault id to pull from; `MAX_VAULT_ID` to withdraw from all vaults
     * @return totalWithdrawn The number of tokens received by recipient.
     */
    function _withdraw(
        IERC20 token,
        address withdrawer,
        address recipient,
        uint256 amount,
        uint256 firstVaultId,
        uint256 lastVaultId
    ) internal returns (uint256 totalWithdrawn) {
        require(firstVaultId <= lastVaultId);

        if (lastVaultId == MAX_VAULT_ID)
            lastVaultId = registry.numVaults(address(token)) - 1;

        for (
            uint256 i = firstVaultId;
            totalWithdrawn + 1 < amount && i <= lastVaultId;
            i++
        ) {
            VaultAPI vault = registry.vaults(address(token), i);

            uint256 withdrawerShares = vault.balanceOf(withdrawer);
            uint256 availableShares = Math.min(
                withdrawerShares,
                vault.maxAvailableShares()
            );
            // Restrict by the allowance that `withdrawer` has given to this contract
            availableShares = Math.min(
                availableShares,
                vault.allowance(withdrawer, address(this))
            );
            if (availableShares == 0) continue;

            uint256 maxShares;
            if (amount != WITHDRAW_EVERYTHING) {
                // Compute amount to withdraw fully to satisfy the request
                uint256 estimatedShares = ((amount - totalWithdrawn) *
                    10**vault.decimals()) / vault.pricePerShare();

                // Limit amount to withdraw to the maximum made available to this contract
                // NOTE: Avoid corner case where `estimatedShares` isn't precise enough
                // NOTE: If `0 < estimatedShares < 1` but `availableShares > 1`, this will withdraw more than necessary
                maxShares = Math.min(availableShares, estimatedShares);
            } else {
                maxShares = availableShares;
            }

            uint256 routerBeforeBal = vault.balanceOf(address(this));

            SafeERC20.safeTransferFrom(
                vault,
                withdrawer,
                address(this),
                maxShares
            );

            uint256 withdrawn = vault.withdraw(maxShares, recipient);
            totalWithdrawn += withdrawn;

            uint256 routerAfterBal = vault.balanceOf(address(this));
            if (routerAfterBal > routerBeforeBal) {
                SafeERC20.safeTransfer(
                    vault,
                    withdrawer,
                    routerAfterBal - routerBeforeBal
                );
            }

            withdrawerShares -= vault.balanceOf(withdrawer);
            emit Withdraw(
                recipient,
                address(vault),
                withdrawerShares,
                withdrawn
            );
        }
    }

    /**
     * @notice Called to redeem all caller's shares from underlying vault, with the proceeds distributed to recipient.
     * @dev The caller must approve this contract to use their vault shares or this call will revert.
     * @param token Address of the ERC20 token to withdraw from the vault.
     * @param recipient Address to receive the withdrawn tokens.
     * @param vaultId Vault id to pull from.
     * @return The number of tokens received by recipient.
     */
    function withdrawShares(
        address token,
        address recipient,
        uint256 vaultId
    ) external returns (uint256) {
        return
            _withdrawShares(
                IERC20(token),
                _msgSender(),
                recipient,
                WITHDRAW_EVERYTHING,
                vaultId
            );
    }

    /**
     * @notice Called to redeem the caller's shares from underlying vault, with the proceeds distributed to recipient.
     * @dev The caller must approve this contract to use their vault shares or this call will revert.
     * @param token Address of the ERC20 token to withdraw from the vault.
     * @param recipient Address to receive the withdrawn tokens.
     * @param sharesAmount Maximum number of shares to withdraw from the vault; If `WITHDRAW_EVERYTHING`, just withdraw everything.
     * @param vaultId Vault id to pull from.
     * @return The number of tokens received by recipient.
     */
    function withdrawShares(
        address token,
        address recipient,
        uint256 sharesAmount,
        uint256 vaultId
    ) external returns (uint256) {
        return
            _withdrawShares(
                IERC20(token),
                _msgSender(),
                recipient,
                sharesAmount,
                vaultId
            );
    }

    /**
     * @notice Called to redeem withdrawer's shares from underlying vault, with the proceeds distributed to recipient.
     * @dev Withdrawer must approve this contract to use their vault shares or this call will revert.
     * @param token Address of the ERC20 token to withdraw from the vault
     * @param withdrawer Address to pull the vault shares from. SECURITY SENSITIVE.
     * @param recipient Address to receive the withdrawn tokens
     * @param sharesAmount Maximum number of tokens to withdraw from the vault; If `WITHDRAW_EVERYTHING`, just withdraw everything.
     * @param vaultId Vault id to pull from.
     * @return withdrawn The number of tokens received by recipient.
     */
    function _withdrawShares(
        IERC20 token,
        address withdrawer,
        address recipient,
        uint256 sharesAmount,
        uint256 vaultId
    ) internal returns (uint256 withdrawn) {
        VaultAPI vault = registry.vaults(address(token), vaultId);

        uint256 sharesBeforeWithdrawal = vault.balanceOf(withdrawer);
        uint256 availableShares = Math.min(
            sharesBeforeWithdrawal,
            vault.maxAvailableShares()
        );

        uint256 maxShares;
        if (sharesAmount != WITHDRAW_EVERYTHING) {
            // Limit amount to withdraw to the maximum made available to this contract
            maxShares = Math.min(availableShares, sharesAmount);
        } else {
            maxShares = availableShares;
        }

        uint256 routerBeforeBal = vault.balanceOf(address(this));

        SafeERC20.safeTransferFrom(vault, withdrawer, address(this), maxShares);

        withdrawn = vault.withdraw(maxShares, recipient);

        uint256 routerAfterBal = vault.balanceOf(address(this));
        if (routerAfterBal > routerBeforeBal) {
            SafeERC20.safeTransfer(
                vault,
                withdrawer,
                routerAfterBal - routerBeforeBal
            );
        }

        uint256 sharesAfterWithdrawal = vault.balanceOf(withdrawer);
        uint256 shares = sharesBeforeWithdrawal - sharesAfterWithdrawal;
        emit Withdraw(recipient, address(vault), shares, withdrawn);
    }

    /**
     * @notice Called to migrate all of the caller's shares to the latest vault.
     * @dev The caller must approve this contract to use their vault shares or this call will revert.
     * @param token Address of the ERC20 token to migrate the vaults of
     * @return The number of tokens migrated.
     */
    function migrate(address token) external returns (uint256) {
        return
            _migrate(
                IERC20(token),
                _msgSender(),
                MIGRATE_EVERYTHING,
                0,
                MAX_VAULT_ID
            );
    }

    /**
     * @notice Called to migrate the caller's shares to the latest vault.
     * @dev The caller must approve this contract to use their vault shares or this call will revert.
     * @param token Address of the ERC20 token to migrate the vaults of
     * @param amount Maximum number of tokens to migrate from all vaults; actual migration may be less. If `MIGRATE_EVERYTHING`, just migrate everything.
     * @return The number of tokens migrated.
     */
    function migrate(address token, uint256 amount) external returns (uint256) {
        return _migrate(IERC20(token), _msgSender(), amount, 0, MAX_VAULT_ID);
    }

    /**
     * @notice Called to migrate the caller's shares to the latest vault.
     * @dev The caller must approve this contract to use their vault shares or this call will revert.
     * @param token Address of the ERC20 token to migrate the vaults of
     * @param amount Maximum number of tokens to migrate from all vaults; actual migration may be less. If `MIGRATE_EVERYTHING`, just migrate everything.
     * @param firstVaultId First vault id to migrate from; 0 to start at the the beginning
     * @param lastVaultId Last vault id to migrate from; `MAX_VAULT_ID` to migrate from all vaults
     * @return The number of tokens migrated.
     */
    function migrate(
        address token,
        uint256 amount,
        uint256 firstVaultId,
        uint256 lastVaultId
    ) external returns (uint256) {
        return
            _migrate(
                IERC20(token),
                _msgSender(),
                amount,
                firstVaultId,
                lastVaultId
            );
    }

    /**
     * @notice Called to migrate migrator's shares to the latest vault.
     * @dev Migrator must approve this contract to use their vault shares or this call will revert.
     * @param token Address of the ERC20 token to migrate the vaults of
     * @param migrator Address to migrate the shares of. SECURITY SENSITIVE.
     * @param amount Maximum number of tokens to migrate from all vaults; actual migration may be less. If `MIGRATE_EVERYTHING`, just migrate everything.
     * @param firstVaultId First vault id to migrate from; 0 to start at the the beginning
     * @param lastVaultId Last vault id to migrate from; `MAX_VAULT_ID` to migrate from all vaults
     * @return migrated The number of tokens migrated.
     */
    function _migrate(
        IERC20 token,
        address migrator,
        uint256 amount,
        uint256 firstVaultId,
        uint256 lastVaultId
    ) internal returns (uint256 migrated) {
        uint256 latestVaultId = registry.numVaults(address(token)) - 1;
        if (amount == 0 || latestVaultId == 0) return 0; // Nothing to migrate, or nowhere to go (not a failure)

        VaultAPI _latestVault = registry.vaults(address(token), latestVaultId);
        uint256 _amount = Math.min(
            amount,
            _latestVault.depositLimit() - _latestVault.totalAssets()
        );

        uint256 beforeWithdrawBal = token.balanceOf(address(this));
        _withdraw(
            token,
            migrator,
            address(this),
            _amount,
            firstVaultId,
            Math.min(lastVaultId, latestVaultId - 1)
        );
        uint256 afterWithdrawBal = token.balanceOf(address(this));
        require(afterWithdrawBal > beforeWithdrawBal, "withdraw failed");

        _deposit(
            token,
            address(this),
            migrator,
            afterWithdrawBal - beforeWithdrawBal,
            latestVaultId
        );
        uint256 afterDepositBal = token.balanceOf(address(this));
        require(afterWithdrawBal > afterDepositBal, "deposit failed");
        migrated = afterWithdrawBal - afterDepositBal;

        if (afterWithdrawBal - beforeWithdrawBal > migrated) {
            SafeERC20.safeTransfer(
                token,
                migrator,
                afterDepositBal - beforeWithdrawBal
            );
        }
    }
}
