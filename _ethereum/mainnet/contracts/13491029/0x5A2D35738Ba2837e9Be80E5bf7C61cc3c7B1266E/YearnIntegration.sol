// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./Controlled.sol";
import "./IIntegration.sol";
import "./IIntegrationMap.sol";
import "./IYearnRegistry.sol";
import "./IYearnVault.sol";
import "./ModuleMapConsumer.sol";

/// @notice Integrates 0x Nodes to Yearn v2 vaults
contract YearnIntegration is
    Initializable,
    ModuleMapConsumer,
    Controlled,
    IIntegration
{
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    address private yearnRegistryAddress;
    mapping(address => uint256) private balances;

    /// @param controllers_ The addresses of the controlling contracts
    /// @param moduleMap_ The address of the module map contract
    /// @param yearnRegistryAddress_ The address of the Yearn registry contract
    function initialize(
        address[] memory controllers_,
        address moduleMap_,
        address yearnRegistryAddress_
    ) public initializer {
        __Controlled_init(controllers_, moduleMap_);
        __ModuleMapConsumer_init(moduleMap_);
        yearnRegistryAddress = yearnRegistryAddress_;
    }

    /// @param tokenAddress The address of the deposited token
    /// @param amount The amount of the token being deposited
    function deposit(address tokenAddress, uint256 amount)
        external
        override
        onlyController
    {
        balances[tokenAddress] += amount;
    }

    /// @notice Withdraws token from the integration
    /// @param tokenAddress The address of the underlying token to withdraw
    /// @param amount The amoutn of the token to withdraw
    function withdraw(address tokenAddress, uint256 amount)
        public
        override
        onlyController
    {
        require(
            amount <= balances[tokenAddress],
            "YearnIntegration::withdraw: Withdraw amount exceeds balance"
        );
        address vaultAddress = getVaultAddress(tokenAddress);
        IERC20MetadataUpgradeable token = IERC20MetadataUpgradeable(
            tokenAddress
        );

        if (token.balanceOf(address(this)) < amount) {
            // Need to withdraw tokens from Yearn vault
            uint256 vaultWithdrawableAmount = getVaultWithdrawableAmount(
                tokenAddress
            );
            if (vaultWithdrawableAmount > 0) {
                // Add 1% to shares amount to withdraw to account for fees
                uint256 sharesAmount = (101 *
                    amount *
                    IERC20MetadataUpgradeable(vaultAddress).balanceOf(
                        address(this)
                    )) /
                    vaultWithdrawableAmount /
                    100;

                if (
                    sharesAmount >
                    IERC20MetadataUpgradeable(vaultAddress).balanceOf(
                        address(this)
                    )
                ) {
                    sharesAmount = IERC20MetadataUpgradeable(vaultAddress)
                        .balanceOf(address(this));
                }

                try IYearnVault(vaultAddress).withdraw(sharesAmount) {} catch {}
            }
        }

        // If there still isn't enough of the withdrawn token, change
        // The withdraw amount to the balance of this contract
        if (token.balanceOf(address(this)) < amount) {
            amount = token.balanceOf(address(this));
        }

        balances[tokenAddress] -= amount;
        token.safeTransfer(moduleMap.getModuleAddress(Modules.Kernel), amount);
    }

    /// @notice Deploys all available tokens to Aave
    function deploy() external override onlyController {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        uint256 tokenCount = integrationMap.getTokenAddressesLength();

        for (uint256 tokenId = 0; tokenId < tokenCount; tokenId++) {
            IERC20MetadataUpgradeable token = IERC20MetadataUpgradeable(
                integrationMap.getTokenAddress(tokenId)
            );
            uint256 tokenAmount = token.balanceOf(address(this));
            address vaultAddress = getVaultAddress(address(token));

            // Check if a vault for this token exists
            if (vaultAddress != address(0)) {
                if (token.allowance(address(this), vaultAddress) == 0) {
                    token.safeApprove(vaultAddress, type(uint256).max);
                }

                if (tokenAmount > 0) {
                    try
                        IYearnVault(vaultAddress).deposit(
                            tokenAmount,
                            address(this)
                        )
                    {} catch {}
                }
            }
        }
    }

    /// @notice Harvests all token yield from the Aave lending pool
    function harvestYield() external override onlyController {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        uint256 tokenCount = integrationMap.getTokenAddressesLength();

        for (uint256 tokenId = 0; tokenId < tokenCount; tokenId++) {
            IERC20MetadataUpgradeable token = IERC20MetadataUpgradeable(
                integrationMap.getTokenAddress(tokenId)
            );
            address vaultAddress = getVaultAddress(address(token));

            // Check if a vault exists for the current token
            if (vaultAddress != address(0)) {
                uint256 availableYieldInShares = getAvailableYieldInShares(
                    address(token)
                );
                if (availableYieldInShares > 0) {
                    uint256 balanceBefore = token.balanceOf(address(this));

                    // Harvest the available yield from Yearn vault
                    try
                        IYearnVault(getVaultAddress(address(token))).withdraw(
                            availableYieldInShares
                        )
                    {
                        uint256 harvestedAmount = token.balanceOf(
                            address(this)
                        ) - balanceBefore;
                        if (harvestedAmount > 0) {
                            // Yield has been harvested, transfer it to the Yield Manager
                            token.safeTransfer(
                                moduleMap.getModuleAddress(
                                    Modules.YieldManager
                                ),
                                harvestedAmount
                            );
                        }
                    } catch {}
                }
            }
        }
    }

    /// @dev This returns the total amount of the underlying token that
    /// @dev has been deposited to the integration contract
    /// @param token The address of the deployed token
    /// @return The amount of the underlying token that can be withdrawn
    function getBalance(address token)
        external
        view
        override
        returns (uint256)
    {
        return balances[token];
    }

    /// @param token The address of the token
    /// @return The address of the vault for the specified token
    function getVaultAddress(address token) public view returns (address) {
        try IYearnRegistry(yearnRegistryAddress).latestVault(token) returns (
            address vaultAddress
        ) {
            return vaultAddress;
        } catch {
            return address(0);
        }
    }

    /// @param token The address of the deposited token
    /// @return The price per vault share in the underlying asset
    function getPricePerShare(address token) public view returns (uint256) {
        return IYearnVault(getVaultAddress(token)).pricePerShare();
    }

    /// @param token The address of the deposited token
    /// @return The amount of available yield to be harvested in value of the share token
    function getAvailableYieldInShares(address token)
        public
        view
        returns (uint256)
    {
        uint256 vaultWithdrawableAmount = getVaultWithdrawableAmount(token);

        if (vaultWithdrawableAmount > balances[token]) {
            return vaultWithdrawableAmount - balances[token];
        } else {
            return 0;
        }
    }

    /// @param token The address of the deposited token
    /// @return The amount of the deposited token that can be withdrawn from the vault
    function getVaultWithdrawableAmount(address token)
        public
        view
        returns (uint256)
    {
        IERC20MetadataUpgradeable shareToken = IERC20MetadataUpgradeable(
            getVaultAddress(token)
        );

        return
            (getPricePerShare(token) * shareToken.balanceOf(address(this))) /
            (10**shareToken.decimals());
    }
}
