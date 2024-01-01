// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./SafeTransferLib.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

/*
    ██████╗ ██████╗ ████████╗
    ██╔══██╗██╔══██╗╚══██╔══╝
    ██████╔╝██║  ██║   ██║
    ██╔══██╗██║  ██║   ██║
    ██║  ██║██████╔╝   ██║
    ╚═╝  ╚═╝╚═════╝    ╚═╝
*/

/// @title RevenueDistributionToken
/// @author Modified from (https://github.com/maple-labs/revenue-distribution-token/blob/main/contracts/RevenueDistributionToken.sol)
abstract contract RevenueDistributionToken is ERC20, Ownable, ReentrancyGuard {
    // =============================================================
    //                       EVENTS
    // =============================================================

    /**
     *  @dev   `caller_` has exchanged `assets_` for `shares_` and transferred them to `owner_`.
     *         MUST be emitted when assets are deposited via the `deposit` or `mint` methods.
     *  @param caller_ The caller of the function that emitted the `Deposit` event.
     *  @param owner_  The owner of the shares.
     *  @param assets_ The amount of assets deposited.
     *  @param shares_ The amount of shares minted.
     */
    event Deposit(address indexed caller_, address indexed owner_, uint256 assets_, uint256 shares_);

    /**
     *  @dev   `caller_` has exchanged `shares_`, owned by `owner_`, for `assets_`, and transferred them to `receiver_`.
     *         MUST be emitted when assets are withdrawn via the `withdraw` or `redeem` methods.
     *  @param caller_   The caller of the function that emitted the `Withdraw` event.
     *  @param receiver_ The receiver of the assets.
     *  @param owner_    The owner of the shares.
     *  @param assets_   The amount of assets withdrawn.
     *  @param shares_   The amount of shares burned.
     */
    event Withdraw(
        address indexed caller_, address indexed receiver_, address indexed owner_, uint256 assets_, uint256 shares_
    );

    /**
     *  @dev   Issuance parameters have been updated after a `_mint` or `_burn`.
     *  @param freeAssets_   Resulting `freeAssets` (y-intercept) value after accounting update.
     *  @param issuanceRate_ The new issuance rate of `asset` until `vestingPeriodFinish_`.
     */
    event IssuanceParamsUpdated(uint256 freeAssets_, uint256 issuanceRate_);

    /**
     *  @dev   `newOwner_` has accepted the transferral of RDT ownership from `previousOwner_`.
     *  @param previousOwner_ The previous RDT owner.
     *  @param newOwner_      The new RDT owner.
     */
    event OwnershipAccepted(address indexed previousOwner_, address indexed newOwner_);

    /**
     *  @dev   `owner_` has set the new pending owner of RDT to `pendingOwner_`.
     *  @param owner_        The current RDT owner.
     *  @param pendingOwner_ The new pending RDT owner.
     */
    event PendingOwnerSet(address indexed owner_, address indexed pendingOwner_);

    /**
     *  @dev   `owner_` has updated the RDT vesting schedule to end at `vestingPeriodFinish_`.
     *  @param owner_               The current RDT owner.
     *  @param vestingPeriodFinish_ When the unvested balance will finish vesting.
     */
    event VestingScheduleUpdated(address indexed owner_, uint256 vestingPeriodFinish_);

    // =============================================================
    //                       ERRORS
    // =============================================================

    error ZeroReceiver();
    error ZeroShares();
    error ZeroAssets();
    error ZeroSupply();
    error InsufficientPermit();

    // =============================================================
    //                       IMMUTABLES
    // =============================================================

    /**
     *  @dev The precision at which the issuance rate is measured.
     */
    uint256 public immutable precision;

    // =============================================================
    //                       STORAGE
    // =============================================================

    /**
     *  @dev    The address of the underlying asset used by the Vault.
     *          MUST be a contract that implements the ERC-20 standard.
     *          MUST NOT revert.
     */
    address public asset; // Underlying ERC-20 asset used by ERC-4626 functionality.

    /**
     *  @dev The total amount of the underlying asset that is currently unlocked and is not time-dependent.
     *       Analogous to the y-intercept in a linear function.
     */
    uint256 public freeAssets;

    /**
     *  @dev The rate of issuance of the vesting schedule that is currently active.
     *       Denominated as the amount of underlying assets vesting per second.
     */
    uint256 public issuanceRate;

    /**
     *  @dev The timestamp of when the linear function was last recalculated.
     *       Analogous to t0 in a linear function.
     */
    uint256 public lastUpdated;

    /**
     *  @dev The end of the current vesting schedule.
     */
    uint256 public vestingPeriodFinish; // Timestamp when current vesting schedule ends.

    // =============================================================
    //                       CONSTRUCTOR
    // =============================================================

    constructor(address owner_, address asset_, uint256 precision_) {
        assembly {
            if or(iszero(owner_), iszero(asset_)) {
                mstore(0x00, "zero address")
                revert(0x00, 0x20)
            }
        }

        _initializeOwner(owner_);

        asset = asset_;

        precision = precision_;
    }

    // =============================================================
    //                       OWNER FUNCTIONS
    // =============================================================

    /**
     *  @dev    Updates the current vesting formula based on the amount of total unvested funds in the contract and the new `vestingPeriod_`.
     *  @param  vestingPeriod_ The amount of time over which all currently unaccounted underlying assets will be vested over.
     *  @return issuanceRate_  The new issuance rate.
     *  @return freeAssets_    The new amount of underlying assets that are unlocked.
     */
    function updateVestingSchedule(uint256 vestingPeriod_)
        external
        virtual
        onlyOwner
        returns (uint256 issuanceRate_, uint256 freeAssets_)
    {
        if (totalSupply() == 0) revert ZeroSupply();

        // Update "y-intercept" to reflect current available asset.
        freeAssets_ = freeAssets = totalAssets();

        // Calculate slope.
        issuanceRate_ =
            issuanceRate = ((ERC20(asset).balanceOf(address(this)) - freeAssets_) * precision) / vestingPeriod_;

        // Update timestamp and period finish.
        vestingPeriodFinish = (lastUpdated = block.timestamp) + vestingPeriod_;

        emit IssuanceParamsUpdated(freeAssets_, issuanceRate_);
        emit VestingScheduleUpdated(msg.sender, vestingPeriodFinish);
    }

    // =============================================================
    //                       STAKER FUNCTIONS
    // =============================================================

    /**
     *  @dev    Mints `shares_` to `receiver_` by depositing `assets_` into the Vault.
     *          MUST emit the {Deposit} event.
     *          MUST revert if all of the assets cannot be deposited (due to insufficient approval, deposit limits, slippage, etc).
     *  @param  assets_   The amount of assets to deposit.
     *  @param  receiver_ The receiver of the shares.
     *  @return shares_   The amount of shares minted.
     */
    function deposit(uint256 assets_, address receiver_) external virtual nonReentrant returns (uint256 shares_) {
        _mint(shares_ = previewDeposit(assets_), assets_, receiver_, msg.sender);
    }

    /**
     *  @dev    Does a ERC4626 `deposit` with a ERC-2612 `permit`.
     *  @param  assets_   The amount of `asset` to deposit.
     *  @param  receiver_ The receiver of the shares.
     *  @param  deadline_ The timestamp after which the `permit` signature is no longer valid.
     *  @param  v_        ECDSA signature v component.
     *  @param  r_        ECDSA signature r component.
     *  @param  s_        ECDSA signature s component.
     *  @return shares_   The amount of shares minted.
     */
    function depositWithPermit(uint256 assets_, address receiver_, uint256 deadline_, uint8 v_, bytes32 r_, bytes32 s_)
        external
        virtual
        nonReentrant
        returns (uint256 shares_)
    {
        ERC20(asset).permit(msg.sender, address(this), assets_, deadline_, v_, r_, s_);
        _mint(shares_ = previewDeposit(assets_), assets_, receiver_, msg.sender);
    }

    /**
     *  @dev    Mints `shares_` to `receiver_` by depositing `assets_` into the Vault.
     *          MUST emit the {Deposit} event.
     *          MUST revert if all of shares cannot be minted (due to insufficient approval, deposit limits, slippage, etc).
     *  @param  shares_   The amount of shares to mint.
     *  @param  receiver_ The receiver of the shares.
     *  @return assets_   The amount of assets deposited.
     */
    function mint(uint256 shares_, address receiver_) external virtual nonReentrant returns (uint256 assets_) {
        _mint(shares_, assets_ = previewMint(shares_), receiver_, msg.sender);
    }

    /**
     *  @dev    Does a ERC4626 `mint` with a ERC-2612 `permit`.
     *  @param  shares_    The amount of `shares` to mint.
     *  @param  receiver_  The receiver of the shares.
     *  @param  maxAssets_ The maximum amount of assets that can be taken, as per the permit.
     *  @param  deadline_  The timestamp after which the `permit` signature is no longer valid.
     *  @param  v_         ECDSA signature v component.
     *  @param  r_         ECDSA signature r component.
     *  @param  s_         ECDSA signature s component.
     *  @return assets_    The amount of shares deposited.
     */
    function mintWithPermit(
        uint256 shares_,
        address receiver_,
        uint256 maxAssets_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external virtual nonReentrant returns (uint256 assets_) {
        if ((assets_ = previewMint(shares_)) > maxAssets_) revert InsufficientPermit();

        ERC20(asset).permit(msg.sender, address(this), maxAssets_, deadline_, v_, r_, s_);
        _mint(shares_, assets_, receiver_, msg.sender);
    }

    /**
     *  @dev    Burns `shares_` from `owner_` and sends `assets_` to `receiver_`.
     *          MUST emit the {Withdraw} event.
     *          MUST revert if all of the shares cannot be redeemed (due to insufficient shares, withdrawal limits, slippage, etc).
     *  @param  shares_   The amount of shares to redeem.
     *  @param  receiver_ The receiver of the assets.
     *  @param  owner_    The owner of the shares.
     *  @return assets_   The amount of assets sent to the receiver.
     */
    function redeem(uint256 shares_, address receiver_, address owner_)
        external
        virtual
        nonReentrant
        returns (uint256 assets_)
    {
        _burn(shares_, assets_ = previewRedeem(shares_), receiver_, owner_, msg.sender);
    }

    /**
     *  @dev    Burns `shares_` from `owner_` and sends `assets_` to `receiver_`.
     *          MUST emit the {Withdraw} event.
     *          MUST revert if all of the assets cannot be withdrawn (due to insufficient assets, withdrawal limits, slippage, etc).
     *  @param  assets_   The amount of assets to withdraw.
     *  @param  receiver_ The receiver of the assets.
     *  @param  owner_    The owner of the assets.
     *  @return shares_   The amount of shares burned from the owner.
     */
    function withdraw(uint256 assets_, address receiver_, address owner_)
        external
        virtual
        nonReentrant
        returns (uint256 shares_)
    {
        _burn(shares_ = previewWithdraw(assets_), assets_, receiver_, owner_, msg.sender);
    }

    // =============================================================
    //                       INTERNAL FUNCTIONS
    // =============================================================

    function _mint(uint256 shares_, uint256 assets_, address receiver_, address caller_) internal {
        if (receiver_ == address(0)) revert ZeroReceiver();
        if (shares_ == uint256(0)) revert ZeroShares();
        if (assets_ == uint256(0)) revert ZeroAssets();

        _mint(receiver_, shares_);

        uint256 freeAssetsCache = freeAssets = totalAssets() + assets_;

        uint256 issuanceRate_ = _updateIssuanceParams();

        emit Deposit(caller_, receiver_, assets_, shares_);
        emit IssuanceParamsUpdated(freeAssetsCache, issuanceRate_);

        SafeTransferLib.safeTransferFrom(asset, caller_, address(this), assets_);
    }

    function _burn(uint256 shares_, uint256 assets_, address receiver_, address owner_, address caller_) internal {
        if (receiver_ == address(0)) revert ZeroReceiver();
        if (shares_ == uint256(0)) revert ZeroShares();
        if (assets_ == uint256(0)) revert ZeroAssets();

        if (caller_ != owner_) {
            _spendAllowance(owner_, caller_, shares_);
        }

        _burn(owner_, shares_);

        uint256 freeAssetsCache = freeAssets = totalAssets() - assets_;

        uint256 issuanceRate_ = _updateIssuanceParams();

        emit Withdraw(caller_, receiver_, owner_, assets_, shares_);
        emit IssuanceParamsUpdated(freeAssetsCache, issuanceRate_);

        SafeTransferLib.safeTransfer(asset, receiver_, assets_);
    }

    function _updateIssuanceParams() internal returns (uint256 issuanceRate_) {
        return issuanceRate = (lastUpdated = block.timestamp) > vestingPeriodFinish ? 0 : issuanceRate;
    }

    function _divRoundUp(uint256 numerator_, uint256 divisor_) internal pure returns (uint256 result_) {
        return (numerator_ / divisor_) + (numerator_ % divisor_ > 0 ? 1 : 0);
    }

    // =============================================================
    //                       VIEW FUNCTIONS
    // =============================================================

    /**
     *  @dev    Returns the amount of underlying assets owned by the specified account.
     *  @param  account_ Address of the account.
     *  @return assets_  Amount of assets owned.
     */
    function balanceOfAssets(address account_) public view virtual returns (uint256 assets_) {
        return convertToAssets(balanceOf(account_));
    }

    /**
     *  @dev    The amount of `assets_` the `shares_` are currently equivalent to.
     *          MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     *          MUST NOT reflect slippage or other on-chain conditions when performing the actual exchange.
     *          MUST NOT show any variations depending on the caller.
     *          MUST NOT revert.
     *  @param  shares_ The amount of shares to convert.
     *  @return assets_ The amount of equivalent assets.
     */
    function convertToAssets(uint256 shares_) public view virtual returns (uint256 assets_) {
        uint256 supply = totalSupply(); // Cache to stack.

        assets_ = supply == 0 ? shares_ : (shares_ * totalAssets()) / supply;
    }

    /**
     *  @dev    The amount of `shares_` the `assets_` are currently equivalent to.
     *          MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     *          MUST NOT reflect slippage or other on-chain conditions when performing the actual exchange.
     *          MUST NOT show any variations depending on the caller.
     *          MUST NOT revert.
     *  @param  assets_ The amount of assets to convert.
     *  @return shares_ The amount of equivalent shares.
     */
    function convertToShares(uint256 assets_) public view virtual returns (uint256 shares_) {
        uint256 supply = totalSupply(); // Cache to stack.

        shares_ = supply == 0 ? assets_ : (assets_ * supply) / totalAssets();
    }

    /**
     *  @dev    Maximum amount of `assets_` that can be deposited on behalf of the `receiver_` through a `deposit` call.
     *          MUST return a limited value if the receiver is subject to any limits, or the maximum value otherwise.
     *          MUST NOT revert.
     *  @param  receiver_ The receiver of the assets.
     *  @return assets_   The maximum amount of assets that can be deposited.
     */
    function maxDeposit(address receiver_) external pure virtual returns (uint256 assets_) {
        receiver_; // Silence warning
        assets_ = type(uint256).max;
    }

    /**
     *  @dev    Maximum amount of `shares_` that can be minted on behalf of the `receiver_` through a `mint` call.
     *          MUST return a limited value if the receiver is subject to any limits, or the maximum value otherwise.
     *          MUST NOT revert.
     *  @param  receiver_ The receiver of the shares.
     *  @return shares_   The maximum amount of shares that can be minted.
     */
    function maxMint(address receiver_) external pure virtual returns (uint256 shares_) {
        receiver_; // Silence warning
        shares_ = type(uint256).max;
    }

    /**
     *  @dev    Maximum amount of `shares_` that can be redeemed from the `owner_` through a `redeem` call.
     *          MUST return a limited value if the owner is subject to any limits, or the total amount of owned shares otherwise.
     *          MUST NOT revert.
     *  @param  owner_  The owner of the shares.
     *  @return shares_ The maximum amount of shares that can be redeemed.
     */
    function maxRedeem(address owner_) external view virtual returns (uint256 shares_) {
        shares_ = balanceOf(owner_);
    }

    /**
     *  @dev    Maximum amount of `assets_` that can be withdrawn from the `owner_` through a `withdraw` call.
     *          MUST return a limited value if the owner is subject to any limits, or the total amount of owned assets otherwise.
     *          MUST NOT revert.
     *  @param  owner_  The owner of the assets.
     *  @return assets_ The maximum amount of assets that can be withdrawn.
     */
    function maxWithdraw(address owner_) external view virtual returns (uint256 assets_) {
        assets_ = balanceOfAssets(owner_);
    }

    /**
     *  @dev    Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given current on-chain conditions.
     *          MUST return as close to and no more than the exact amount of shares that would be minted in a `deposit` call in the same transaction.
     *          MUST NOT account for deposit limits like those returned from `maxDeposit` and should always act as though the deposit would be accepted.
     *          MUST NOT revert.
     *  @param  assets_ The amount of assets to deposit.
     *  @return shares_ The amount of shares that would be minted.
     */
    function previewDeposit(uint256 assets_) public view virtual returns (uint256 shares_) {
        // As per https://eips.ethereum.org/EIPS/eip-4626#security-considerations,
        // it should round DOWN if it’s calculating the amount of shares to issue to a user, given an amount of assets provided.
        shares_ = convertToShares(assets_);
    }

    /**
     *  @dev    Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given current on-chain conditions.
     *          MUST return as close to and no fewer than the exact amount of assets that would be deposited in a `mint` call in the same transaction.
     *          MUST NOT account for mint limits like those returned from `maxMint` and should always act as though the minting would be accepted.
     *          MUST NOT revert.
     *  @param  shares_ The amount of shares to mint.
     *  @return assets_ The amount of assets that would be deposited.
     */
    function previewMint(uint256 shares_) public view virtual returns (uint256 assets_) {
        uint256 supply = totalSupply(); // Cache to stack.

        // As per https://eips.ethereum.org/EIPS/eip-4626#security-considerations,
        // it should round UP if it’s calculating the amount of assets a user must provide, to be issued a given amount of shares.
        assets_ = supply == 0 ? shares_ : _divRoundUp(shares_ * totalAssets(), supply);
    }

    /**
     *  @dev    Allows an on-chain or off-chain user to simulate the effects of their redemption at the current block, given current on-chain conditions.
     *          MUST return as close to and no more than the exact amount of assets that would be withdrawn in a `redeem` call in the same transaction.
     *          MUST NOT account for redemption limits like those returned from `maxRedeem` and should always act as though the redemption would be accepted.
     *          MUST NOT revert.
     *  @param  shares_ The amount of shares to redeem.
     *  @return assets_ The amount of assets that would be withdrawn.
     */
    function previewRedeem(uint256 shares_) public view virtual returns (uint256 assets_) {
        // As per https://eips.ethereum.org/EIPS/eip-4626#security-considerations,
        // it should round DOWN if it’s calculating the amount of assets to send to a user, given amount of shares returned.
        assets_ = convertToAssets(shares_);
    }

    /**
     *  @dev    Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block, given current on-chain conditions.
     *          MUST return as close to and no fewer than the exact amount of shares that would be burned in a `withdraw` call in the same transaction.
     *          MUST NOT account for withdrawal limits like those returned from `maxWithdraw` and should always act as though the withdrawal would be accepted.
     *          MUST NOT revert.
     *  @param  assets_ The amount of assets to withdraw.
     *  @return shares_ The amount of shares that would be redeemed.
     */
    function previewWithdraw(uint256 assets_) public view virtual returns (uint256 shares_) {
        uint256 supply = totalSupply(); // Cache to stack.

        // As per https://eips.ethereum.org/EIPS/eip-4626#security-considerations,
        // it should round UP if it’s calculating the amount of shares a user must return, to be sent a given amount of assets.
        shares_ = supply == 0 ? assets_ : _divRoundUp(assets_ * supply, totalAssets());
    }

    /**
     *  @dev    Total amount of the underlying asset that is managed by the Vault.
     *          SHOULD include compounding that occurs from any yields.
     *          MUST NOT revert.
     *  @return totalAssets_ The total amount of assets the Vault manages.
     */
    function totalAssets() public view virtual returns (uint256 totalAssets_) {
        uint256 issuanceRate_ = issuanceRate;

        if (issuanceRate_ == 0) return freeAssets;

        uint256 vestingPeriodFinish_ = vestingPeriodFinish;
        uint256 lastUpdated_ = lastUpdated;

        uint256 vestingTimePassed = block.timestamp > vestingPeriodFinish_
            ? vestingPeriodFinish_ - lastUpdated_
            : block.timestamp - lastUpdated_;

        return ((issuanceRate_ * vestingTimePassed) / precision) + freeAssets;
    }
}
