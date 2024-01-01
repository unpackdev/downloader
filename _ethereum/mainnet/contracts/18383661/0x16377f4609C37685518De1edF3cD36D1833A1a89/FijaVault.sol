// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC20.sol";
import "./ERC20.sol";

import "./FijaERC4626Base.sol";
import "./IFijaStrategy.sol";
import "./IFijaVault.sol";
import "./errors.sol";

///
/// @title FijaVault
/// @author Fija
/// @notice Enables users to deposit assets and receive vault tokens in return.
/// User can withdraw back assets by burning their vault tokens,
/// potentially increased for vault interest.
/// @dev In order for Vault to function properly, following needs to be completed:
/// - "Deployer" deployed Strategy which vault will use and it's address is known
/// - "Deployer" invoked Strategy.addAddressToWhitelist and added this Vault to Strategy's whitelist
///
contract FijaVault is IFijaVault, FijaERC4626Base {
    IFijaStrategy private _strategy;
    StrategyCandidate private _strategyCandidate;

    uint256 private _approvalDelay;

    constructor(
        IFijaStrategy strategy_,
        IERC20 asset_,
        string memory tokenName_,
        string memory tokenSymbol_,
        address governance_,
        address reseller_,
        uint256 approvalDelay_,
        uint256 maxTicketSize_,
        uint256 maxVaultValue_
    )
        FijaERC4626Base(
            asset_,
            governance_,
            reseller_,
            tokenName_,
            tokenSymbol_,
            maxTicketSize_,
            maxVaultValue_
        )
    {
        if (address(strategy_) == address(0)) {
            revert VaultStrategyUndefined();
        }
        if (strategy_.asset() != asset()) {
            revert VaultNoAssetMatching();
        }

        _strategy = strategy_;
        _approvalDelay = approvalDelay_;
    }

    ///
    /// @inheritdoc IFijaVault
    ///
    function strategy() public view virtual override returns (address) {
        return address(_strategy);
    }

    ///
    /// @inheritdoc IFijaVault
    ///
    function proposedStrategy()
        public
        view
        virtual
        override
        returns (StrategyCandidate memory)
    {
        return _strategyCandidate;
    }

    ///
    /// @inheritdoc IFijaVault
    ///
    function approvalDelay() public view virtual override returns (uint256) {
        return _approvalDelay;
    }

    ///
    /// NOTE: vault needs to be added to proposed strategy whitelist prior to calling this function
    /// Emits IFijaVault.NewStrategyCandidateEvent
    /// @inheritdoc IFijaVault
    ///
    function proposeStrategy(
        IFijaStrategy strategyCandidate
    ) public virtual override onlyGovernance {
        if (!strategyCandidate.isWhitelisted(address(this))) {
            revert VaultNotWhitelisted();
        }

        _strategyCandidate = StrategyCandidate({
            implementation: address(strategyCandidate),
            proposedTime: uint64(block.timestamp)
        });

        emit NewStrategyCandidateEvent(
            address(strategyCandidate),
            block.timestamp
        );
    }

    ///
    /// NOTE: this can only be called when proposedTime + approvalDelay has passed.
    /// For safety it sets StrategyCandidate.implementation to 0 address and proposedTime to over 130 years from now
    /// Emits IFijaVault.UpdateStrategyEvent
    /// @inheritdoc IFijaVault
    ///
    function updateStrategy() public virtual override onlyGovernance {
        if (_strategyCandidate.implementation == address(0)) {
            revert VaultNoUpdateCandidate();
        }
        if (
            _strategyCandidate.proposedTime + _approvalDelay >= block.timestamp
        ) {
            revert VaultUpdateStrategyTimeError();
        }

        emit UpdateStrategyEvent(
            _strategyCandidate.implementation,
            block.timestamp
        );

        // get assets back from strategy in batches
        uint256 remainingTokens = _strategy.balanceOf(address(this));
        while (remainingTokens > 0) {
            uint256 maxRedeem = _strategy.maxRedeem(address(this));
            uint256 redeemAmount = remainingTokens > maxRedeem
                ? maxRedeem
                : remainingTokens;
            _strategy.redeem(redeemAmount, address(this), address(this));
            remainingTokens -= redeemAmount;
        }

        // get all assets in the vault (assets received from strategy + outstanding assets if any)
        uint256 totalAssetsInVault = 0;
        if (asset() != ETH) {
            totalAssetsInVault = IERC20(asset()).balanceOf(address(this));
        } else {
            totalAssetsInVault = address(this).balance;
        }

        // assign new strategy
        _strategy = IFijaStrategy(_strategyCandidate.implementation);

        // vault is giving new Strategy approval for asset transfer
        if (asset() != ETH) {
            SafeERC20.forceApprove(
                IERC20(asset()),
                address(_strategy),
                totalAssetsInVault
            );
        }

        // deposit assets received from old strategy to new strategy and receive strategy tokens from new strategy,
        // in batches
        while (totalAssetsInVault > 0) {
            uint256 maxDeposit = _strategy.maxDeposit(address(this));
            uint256 depositAmount = totalAssetsInVault > maxDeposit
                ? maxDeposit
                : totalAssetsInVault;

            uint256 ethValue = 0;
            if (asset() == ETH) {
                ethValue = depositAmount;
            }
            _strategy.deposit{value: ethValue}(depositAmount, address(this));
            totalAssetsInVault -= depositAmount;
        }

        // resets strategy candidate after strategy update has been completed
        _strategyCandidate.implementation = address(0);
        _strategyCandidate.proposedTime = type(uint64).max; //set proposed time to the far future
    }

    ///
    /// @dev gets amount of assets under vault management
    /// @return amount in assets
    ///
    function totalAssets()
        public
        view
        virtual
        override(FijaERC4626Base, IERC4626)
        returns (uint256)
    {
        if (asset() == ETH) {
            return
                _strategy.convertToAssets(_strategy.balanceOf(address(this))) +
                address(this).balance;
        } else {
            return
                _strategy.convertToAssets(_strategy.balanceOf(address(this))) +
                IERC20(asset()).balanceOf(address(this));
        }
    }

    ///
    /// @dev calculates amount of vault tokens receiver will get from the Vault based on asset deposit.
    /// @param assets amount of assets caller wants to deposit
    /// @param receiver address of the owner of deposit once deposit completes, this address will receive vault tokens.
    /// @return amount of vault tokens receiver will receive
    /// NOTE: Main entry method for receiving deposits, which will be then distrubuted through strategy contract.
    /// Access rights for the method are defined by FijaERC4626Base contract.
    /// Caller and receiver must be whitelisted
    /// Emits IERC4626.Deposit
    ///
    function deposit(
        uint256 assets,
        address receiver
    )
        public
        payable
        virtual
        override(FijaERC4626Base, IERC4626)
        returns (uint256)
    {
        uint256 tokens = super.deposit(assets, receiver);
        uint256 allAssets;
        if (asset() == ETH) {
            allAssets = address(this).balance;
            _strategy.deposit{value: allAssets}(allAssets, address(this));
        } else {
            allAssets = IERC20(asset()).balanceOf(address(this));
            // Vault is giving Strategy approval for asset transfer
            SafeERC20.forceApprove(
                IERC20(asset()),
                address(_strategy),
                allAssets
            );
            _strategy.deposit(allAssets, address(this));
        }

        return tokens;
    }

    ///
    /// @dev Burns exact number of vault tokens from owner and sends assets to receiver.
    /// @param tokens amount of vault tokens caller wants to redeem
    /// @param receiver address of the asset receiver
    /// @param owner address of the owner of vault tokens
    /// @return amount of assets receiver will receive based on exact burnt vault tokens
    /// NOTE: Unwinds investments from strategy and returns assets.
    /// Access rights for the method are defined by FijaERC4626Base contract.
    /// Caller, receiver and owner must be whitelisted
    /// Emits IERC4626.Withdraw
    ///
    function redeem(
        uint256 tokens,
        address receiver,
        address owner
    ) public virtual override(FijaERC4626Base, IERC4626) returns (uint256) {
        uint256 assets = previewRedeem(tokens);

        uint256 currentBalance;
        if (asset() == ETH) {
            currentBalance = address(this).balance;
        } else {
            currentBalance = IERC20(asset()).balanceOf(address(this));
        }

        if (assets > currentBalance) {
            uint256 strategyTokens = _strategy.previewWithdraw(
                assets - currentBalance
            );
            _strategy.redeem(strategyTokens, address(this), address(this));
        }
        return super.redeem(tokens, receiver, owner);
    }

    ///
    /// @dev Burns tokens from owner and sends exact number of assets to receiver
    /// @param assets amount of assets caller wants to withdraw
    /// @param receiver address of the asset receiver
    /// @param owner address of the owner of vault tokens
    /// @return amount of vault tokens burnt based on exact assets requested
    /// NOTE: Unwinds investments from strategy and returns assets.
    /// Access rights for the method are defined by FijaERC4626Base contract.
    /// Caller, receiver and owner must be whitelisted
    /// Emits IERC4626.Withdraw
    ///
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override(FijaERC4626Base, IERC4626) returns (uint256) {
        uint256 currentBalance;
        if (asset() == ETH) {
            currentBalance = address(this).balance;
        } else {
            currentBalance = IERC20(asset()).balanceOf(address(this));
        }

        if (assets > currentBalance) {
            _strategy.withdraw(
                assets - currentBalance,
                address(this),
                address(this)
            );
        }
        return super.withdraw(assets, receiver, owner);
    }

    ///
    /// NOTE: only reseller access
    /// @inheritdoc IFijaACL
    ///
    function addAddressToWhitelist(
        address addr
    ) public virtual override onlyReseller returns (bool) {
        return super.addAddressToWhitelist(addr);
    }

    ///
    /// NOTE: only reseller access
    /// @inheritdoc IFijaACL
    ///
    function removeAddressFromWhitelist(
        address addr
    ) public virtual override onlyReseller returns (bool) {
        return super.removeAddressFromWhitelist(addr);
    }

    receive() external payable {}
}
