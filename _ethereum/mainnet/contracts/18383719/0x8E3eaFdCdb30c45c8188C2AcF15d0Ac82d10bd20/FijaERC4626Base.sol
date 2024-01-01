// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC4626.sol";
import "./FijaACL.sol";
import "./IFijaERC4626Base.sol";
import "./Math.sol";

///
/// @title Fija ERC4626 Base contract
/// @author Fija
/// @notice Used as template for implementing ERC4626
/// @dev This is mainly used for adding access rights to specific methods.
/// NOTE: All mint related methods are disabled from ERC4626
///
abstract contract FijaERC4626Base is IFijaERC4626Base, FijaACL, ERC4626 {
    using Math for uint256;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    ///
    /// @dev maximum amount to deposit/redeem/withdraw in assets in single call
    /// NOTE: if user wants to deposits/withdrawls/redeem with amounts above this limit
    /// transaction will be rejected
    ///
    uint256 internal immutable MAX_TICKET_SIZE;

    ///
    /// @dev maximum value of vault in assets
    /// NOTE: all deposits above this value will be rejected
    ///
    uint256 internal immutable MAX_VAULT_VALUE;

    constructor(
        IERC20 asset_,
        address governance_,
        address reseller_,
        string memory tokenName_,
        string memory tokenSymbol_,
        uint256 maxTicketSize_,
        uint256 maxVaultValue_
    )
        ERC4626(asset_)
        ERC20(tokenName_, tokenSymbol_)
        FijaACL(governance_, reseller_)
    {
        MAX_TICKET_SIZE = maxTicketSize_;
        MAX_VAULT_VALUE = maxVaultValue_;
    }

    ///
    /// @dev Throws if zero input amount (on deposit, withdraw, redeem)
    ///
    modifier nonZeroAmount(uint256 amount) {
        if (amount == 0) {
            revert FijaZeroInput();
        }
        _;
    }

    ///
    /// @inheritdoc IERC4626
    ///
    function totalAssets()
        public
        view
        virtual
        override(IERC4626, ERC4626)
        returns (uint256)
    {
        if (asset() == ETH) {
            return address(this).balance;
        } else {
            return IERC20(asset()).balanceOf(address(this));
        }
    }

    ///
    /// @inheritdoc IFijaERC4626Base
    ///
    function convertToTokens(
        uint256 assets
    ) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    ///
    /// NOTE: caller and "to" must be whitelisted
    /// @inheritdoc IERC20
    ///
    function transfer(
        address to,
        uint256 amount
    ) public virtual override(ERC20, IERC20) onlyWhitelisted returns (bool) {
        if (!isWhitelisted(to)) {
            revert ACLTransferUserNotWhitelist();
        }
        super.transfer(to, amount);

        return true;
    }

    ///
    /// NOTE: caller and "to" must be whitelisted
    /// @inheritdoc IERC20
    ///
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override(ERC20, IERC20) onlyWhitelisted returns (bool) {
        if (!isWhitelisted(from) || !isWhitelisted(to)) {
            revert ACLTransferUserNotWhitelist();
        }
        super.transferFrom(from, to, amount);

        return true;
    }

    ///
    /// NOTE: only whitelisted access
    /// @inheritdoc IERC20
    ///
    function approve(
        address spender,
        uint256 amount
    ) public virtual override(ERC20, IERC20) onlyWhitelisted returns (bool) {
        return super.approve(spender, amount);
    }

    ///
    /// NOTE: only whitelisted access
    /// @inheritdoc ERC20
    ///
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual override onlyWhitelisted returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    ///
    /// NOTE: only whitelisted access
    /// @inheritdoc ERC20
    ///
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual override onlyWhitelisted returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    ///
    /// NOTE: DISABLED
    /// @return 0
    /// @inheritdoc IERC4626
    ///
    function mint(
        uint256,
        address
    ) public virtual override(ERC4626, IERC4626) returns (uint256) {
        return 0;
    }

    ///
    /// NOTE: DISABLED
    /// @return 0
    /// @inheritdoc IERC4626
    ///
    function previewMint(
        uint256
    ) public view virtual override(ERC4626, IERC4626) returns (uint256) {
        return 0;
    }

    ///
    /// NOTE: DISABLED
    /// @return 0
    /// @inheritdoc IERC4626
    ///
    function maxMint(
        address
    ) public view virtual override(ERC4626, IERC4626) returns (uint256) {
        return 0;
    }

    ///
    /// @dev calculates maximum amount user is allowed to deposit in assets,
    /// this depends of current value of vault and user deposit amount.
    /// It is controlled by MAX_TICKET_SIZE and MAX_VAULT_VALUE
    /// @return maximum amount user can deposit to the vault in assets
    ///
    function maxDeposit(
        address receiver
    ) public view virtual override(ERC4626, IERC4626) returns (uint256) {
        return _maxDeposit(receiver, totalAssets());
    }

    ///
    /// @dev calculates maximum amount user is allowed to withdraw in assets,
    /// this on user withdrawal amount request.
    /// It is controlled by MAX_TICKET_SIZE
    /// @return maximum amount user can withdraw from the vault in assets
    ///
    function maxWithdraw(
        address owner
    ) public view virtual override(ERC4626, IERC4626) returns (uint256) {
        uint256 assets = _convertToAssets(balanceOf(owner), Math.Rounding.Down);

        return assets > MAX_TICKET_SIZE ? MAX_TICKET_SIZE : assets;
    }

    ///
    /// @dev calculates maximum amount user is allowed to redeem in tokens from the vault
    /// It is controlled by MAX_TICKET_SIZE
    /// @return maximum amount user can redeem from the vault in tokens
    ///
    function maxRedeem(
        address owner
    ) public view virtual override(ERC4626, IERC4626) returns (uint256) {
        uint256 tokens = balanceOf(owner);
        uint256 assets = _convertToAssets(tokens, Math.Rounding.Down);

        return
            assets > MAX_TICKET_SIZE
                ? convertToTokens(MAX_TICKET_SIZE)
                : tokens;
    }

    ///
    /// @dev calculates amount of tokens receiver will get based on asset deposit.
    /// @param assets amount of assets caller wants to deposit
    /// @param receiver address of the owner of deposit once deposit completes, this address will receive tokens.
    /// @return amount of tokens receiver will receive
    /// NOTE: this is protected generic template method for deposits and child contracts
    /// should provide necessary overriding.
    /// Ensure to call super.deposit from child contract to enforce access rights.
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
        override(ERC4626, IERC4626)
        onlyWhitelisted
        nonZeroAmount(assets)
        onlyReceiverWhitelisted(receiver)
        returns (uint256)
    {
        if (asset() == ETH) {
            if (assets != msg.value) {
                revert TransferDisbalance();
            }
            uint256 totalAssetBeforeDeposit = totalAssets() - msg.value;
            require(
                assets <= _maxDeposit(receiver, totalAssetBeforeDeposit),
                "ERC4626: deposit more than max"
            );

            uint256 supply = totalSupply();
            uint256 tokens = (assets == 0 || supply == 0)
                ? _initialConvertToShares(assets, Math.Rounding.Down)
                : assets.mulDiv(
                    supply,
                    totalAssetBeforeDeposit,
                    Math.Rounding.Down
                );

            _mint(receiver, tokens);

            emit Deposit(msg.sender, receiver, assets, tokens);

            return tokens;
        } else {
            return super.deposit(assets, receiver);
        }
    }

    ///
    /// @dev Burns exact number of tokens from owner and sends assets to receiver.
    /// @param tokens amount of tokens caller wants to redeem
    /// @param receiver address of the asset receiver
    /// @param owner address of the owner of tokens
    /// @return amount of assets receiver will receive based on exact burnt tokens
    /// NOTE: this is protected generic template method for redeeming and child contracts
    /// should provide necessary overriding.
    /// Ensure to call super.redeem from child contract to enforce access rights.
    /// Caller, receiver and owner must be whitelisted
    /// Emits IERC4626.Withdraw
    ///
    function redeem(
        uint256 tokens,
        address receiver,
        address owner
    )
        public
        virtual
        override(ERC4626, IERC4626)
        onlyWhitelisted
        nonZeroAmount(tokens)
        onlyReceiverOwnerWhitelisted(receiver, owner)
        returns (uint256)
    {
        if (asset() == ETH) {
            require(
                tokens <= maxRedeem(owner),
                "ERC4626: redeem more than max"
            );
            uint256 assets = previewRedeem(tokens);

            _burn(owner, tokens);

            (bool success, ) = payable(receiver).call{value: assets}("");
            if (!success) {
                revert TransferFailed();
            }
            emit Withdraw(msg.sender, receiver, owner, assets, tokens);

            return assets;
        } else {
            return super.redeem(tokens, receiver, owner);
        }
    }

    ///
    /// @dev Burns tokens from owner and sends exact number of assets to receiver
    /// @param assets amount of assets caller wants to withdraw
    /// @param receiver address of the asset receiver
    /// @param owner address of the owner of tokens
    /// @return amount of tokens burnt based on exact assets requested
    /// NOTE: this is protected generic template method for withdrawing and child contracts
    /// should provide necessary overriding.
    /// Ensure to call super.withdraw from child contract to enforce access rights.
    /// Caller, receiver and owner must be whitelisted
    /// Emits IERC4626.Withdraw
    ///
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    )
        public
        virtual
        override(ERC4626, IERC4626)
        onlyWhitelisted
        nonZeroAmount(assets)
        onlyReceiverOwnerWhitelisted(receiver, owner)
        returns (uint256)
    {
        if (asset() == ETH) {
            require(
                assets <= maxWithdraw(owner),
                "ERC4626: withdraw more than max"
            );

            uint256 tokens = previewWithdraw(assets);

            _burn(owner, tokens);
            (bool success, ) = payable(receiver).call{value: assets}("");
            if (!success) {
                revert TransferFailed();
            }
            emit Withdraw(msg.sender, receiver, owner, assets, tokens);

            return tokens;
        } else {
            return super.withdraw(assets, receiver, owner);
        }
    }

    ///
    /// @dev helper method - calculates maximum amount user is allowed to deposit in assets,
    /// this depends of current value of vault and user deposit amount.
    /// It is controlled by MAX_TICKET_SIZE and MAX_VAULT_VALUE
    /// @param totalAsset total assets in deposit currency
    /// @return maximum amount user can deposit to the vault in assets
    ///
    function _maxDeposit(
        address,
        uint256 totalAsset
    ) internal view returns (uint256) {
        if (MAX_VAULT_VALUE >= totalAsset) {
            uint256 maxValueDiff = MAX_VAULT_VALUE - totalAsset;
            if (maxValueDiff <= MAX_TICKET_SIZE) {
                return maxValueDiff;
            } else {
                return MAX_TICKET_SIZE;
            }
        } else {
            return 0;
        }
    }
}
