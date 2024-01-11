// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "./ERC20Upgradeable.sol";
import "./ERC20.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./draft-ERC20PermitUpgradeable.sol";
import "./Initializable.sol";
import "./BaseRouterUpgradeableV1.sol";
import "./MathUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IAccessControlUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IBaseRouterUpgradeable.sol";
import "./IFeeUpgradeable.sol";
import "./LibUpgradeable.sol";

contract UnbkV1 is
    Initializable,
    ERC20Upgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ERC20PermitUpgradeable
{
    using MathUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;

    uint8 private _decimals;

    mapping(address => uint256) private _depositedFunds;

    IERC20Upgradeable public token;
    IAccessControlUpgradeable public roles;
    IBaseRouterUpgradeable public baseRouter;
    IFeeupgradeable public feeResolver;

    address public lastMigratedVault;

    event RolesSet(address indexed oldRoles, address indexed newRoles);

    event FundsDeposited(
        address indexed investor,
        uint256 tokenAmount,
        uint256 shares
    );

    event FundsWithdrawn(
        address indexed receiver,
        uint256 collectedFee,
        uint256 investedTokens,
        uint256 transferredFunds,
        bool isCollectorTriggerer
    );

    event FeesCollected(
        address indexed triggererAccount,
        address indexed receiver,
        uint256 collectedFees
    );

    event RouterSet(address indexed oldRouter, address indexed newRouter);

    event FeeResolverSet(
        address indexed oldFeeResolver,
        address indexed newFeeResolver
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _token,
        string memory name,
        string memory symbol,
        address _roles,
        address newRouter,
        address newFeeResolver,
        address firstVaultReference
    ) public initializer {
        __ERC20_init(name, symbol);
        __Pausable_init();
        __Ownable_init();
        __ERC20Permit_init(name);
        token = IERC20Upgradeable(_token);
        _setRoleContract(_roles);
        _setupDecimals(uint8(ERC20(address(token)).decimals()));
        _setRouter(newRouter);
        _setFeeResolver(newFeeResolver);
        lastMigratedVault = firstVaultReference;
    }

    function _setFeeResolver(address _newFeeResolver) private {
        _validateAddress(_newFeeResolver);
        address oldFeeResolver = address(feeResolver);
        feeResolver = IFeeupgradeable(_newFeeResolver);
        _getFeeCollector();
        emit FeeResolverSet(oldFeeResolver, address(feeResolver));
    }

    function _getFeeCollector() private view returns (address) {
        address _feeCollector = feeResolver.getFeeCollector();
        _validateAddress(_feeCollector);
        return _feeCollector;
    }

    function _validateAddress(address _addr) private view {
        require(_addr != address(0) && _addr != address(this), "IA");
    }

    function _setRouter(address _router) private {
        _validateAddress(_router);
        address oldRouter = address(baseRouter);
        baseRouter = IBaseRouterUpgradeable(_router);
        emit RouterSet(oldRouter, _router);
    }

    function _setRoleContract(address _roles) private {
        _validateAddress(_roles);
        address oldRoles = address(roles);
        roles = IAccessControlUpgradeable(_roles);
        emit RolesSet(oldRoles, address(roles));
    }

    function setRoleContract(address newRoles) external onlyOwner {
        _setRoleContract(newRoles);
    }

    function setRouter(address newRouter) external onlyOwner {
        _validateAddress(newRouter);
        _setRouter(newRouter);
    }

    function setFeeResolver(address newFeeResolver) external onlyOwner {
        _validateAddress(newFeeResolver);
        _setFeeResolver(newFeeResolver);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function claimFees() external returns (uint256) {
        _verifyTreasuryRole();
        return _claimFees(token, _getFeeCollector());
    }

    function _getChainId() private view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    function _shareValue(uint256 numShares) private view returns (uint256) {
        uint256 totalShares = totalSupply();

        if (totalShares > 0) {
            return
                totalVaultBalance(address(this)).mul(numShares).div(
                    totalShares
                );
        } else {
            return numShares;
        }
    }

    function shareValue(uint256 numShares) external view returns (uint256) {
        return _shareValue(numShares);
    }

    function _sharesForValue(uint256 amount) private view returns (uint256) {
        // total wrapper assets before deposit (assumes deposit already occured)
        uint256 totalBalance = totalVaultBalance(address(this)); //total amount of tokens
        // make sure totalSupply() > 0 to avoid  corner case when a little amount of funds remain in the vault,
        // making true the condition "totalBalance > amount"
        if (totalBalance > amount && totalSupply() > 0) {
            return totalSupply().mul(amount).div(totalBalance.sub(amount));
        } else {
            return amount;
        }
    }

    function deposit() external whenNotPaused returns (uint256) {
        return deposit(HelpersUpgradeable.getDepositEverythingAmount()); // Deposit everything
    }

    function deposit(uint256 amount)
        public
        whenNotPaused
        returns (uint256 deposited)
    {
        deposited = _deposit(msg.sender, address(this), amount, true); // `true` = pull from `msg.sender`
        //trace tokens deposited into the vault
        _traceDepositedFunds(msg.sender, deposited);
        uint256 shares = _sharesForValue(deposited); // NOTE: Must be calculated after deposit is handled
        _mint(msg.sender, shares);
        emit FundsDeposited(msg.sender, deposited, shares);
    }

    function withdraw() external whenNotPaused returns (uint256) {
        return withdraw(balanceOf(msg.sender));
    }

    /**
     * @notice From message sender, withdraws specified amount of shares
     * @param shares The number of shares to withdraw
     */
    function withdraw(uint256 shares) public whenNotPaused returns (uint256) {
        return _withdraw(shares, feeResolver.getFee());
    }

    /**
     * @notice From message sender, withdraws specified amount of shares
     * @param shares The number of shares to withdraw (erc20 tokens in this contract)
     * @param sFee service Fee
     */
    function _withdraw(uint256 shares, uint256 sFee)
        private
        returns (uint256 withdrawn)
    {
        require(shares <= balanceOf(msg.sender), "ISh");
        uint256 funds = getDepositedFunds(msg.sender);
        uint256 sharesToInvestedTokens = funds.mul(shares).div(
            balanceOf(msg.sender)
        );
        withdrawn = _withdraw(
            address(this),
            msg.sender,
            _shareValue(shares),
            true, // `true` = withdraw from `bestVault`
            sharesToInvestedTokens,
            sFee,
            feeResolver.geThresholdMinimumFee()
        );

        _decreaseDepositedFunds(msg.sender, sharesToInvestedTokens);
        _burn(msg.sender, shares);
    }

    function migrate() external whenNotPaused returns (uint256) {
        _verifyContractUpdaterRole();
        return _migrate(address(this));
    }

    function migrateAllWithLossTolerance(uint256 maxMigrationLoss)
        external
        whenNotPaused
        returns (uint256)
    {
        _verifyContractUpdaterRole();
        return
            _migrate(
                address(this),
                HelpersUpgradeable.getMigrateEverythingAmount(),
                maxMigrationLoss
            );
    }

    function migrate(uint256 amount, uint256 maxMigrationLoss)
        external
        whenNotPaused
        returns (uint256)
    {
        _verifyContractUpdaterRole();
        return _migrate(address(this), amount, maxMigrationLoss);
    }

    function _migrate(address account) private returns (uint256) {
        return
            _migrate(account, HelpersUpgradeable.getMigrateEverythingAmount());
    }

    function _migrate(address account, uint256 amount)
        private
        returns (uint256)
    {
        // NOTE: In practice, it was discovered that <50 was the maximum we've see for this variance
        return _migrate(account, amount, 0);
    }

    function _migrate(
        address account,
        uint256 amount,
        uint256 maxMigrationLoss
    ) private returns (uint256 migrated) {
        VaultAPI _bestVault = bestVault();

        // NOTE: Only override if we aren't migrating everything
        uint256 _depositLimit = _bestVault.depositLimit();
        uint256 _totalAssets = _bestVault.totalAssets();
        if (_depositLimit <= _totalAssets) return 0; // Nothing to migrate (not a failure)

        uint256 _amount = amount;
        if (
            _depositLimit < HelpersUpgradeable.getUncappedDepositsAmount() &&
            _amount < HelpersUpgradeable.getMigrateEverythingAmount()
        ) {
            // Can only deposit up to this amount
            uint256 _depositLeft = _depositLimit.sub(_totalAssets);
            if (_amount > _depositLeft) _amount = _depositLeft;
        }

        if (_amount > 0) {
            // NOTE: `false` = don't withdraw from `_bestVault`
            uint256 withdrawn = _withdraw(
                account,
                address(this),
                _amount,
                false,
                0,
                0, //no %fee
                type(uint256).max //threshold sent to max so not to emit events
            );
            if (withdrawn == 0) {
                lastMigratedVault = address(bestVault()); //no funds to migrate so just point to the current latest vault
                return 0;
            } // Nothing to migrate (not a failure)

            // NOTE: `false` = don't do `transferFrom` because it's already local
            migrated = _deposit(
                token,
                address(this),
                account,
                withdrawn,
                false
            );
            // NOTE: Due to the precision loss of certain calculations, there is a small inefficency
            //       on how migrations are calculated, and this could lead to a DoS issue. Hence, this
            //       value is made to be configurable to allow the user to specify how much is acceptable
            require(withdrawn.sub(migrated) <= maxMigrationLoss, "IMA"); //avoiding the vault taking more than expected by throwing
            lastMigratedVault = address(_bestVault);
        } // else: nothing to migrate! (not a failure)
    }

    function transfer(address recipient, uint256 shares)
        public
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        require(shares <= balanceOf(msg.sender), "ISh");

        uint256 funds = getDepositedFunds(msg.sender);
        uint256 sharesToTokens = funds.mul(shares).div(balanceOf(msg.sender));
        _decreaseDepositedFunds(msg.sender, sharesToTokens);

        _traceDepositedFunds(recipient, sharesToTokens);
        _transfer(_msgSender(), recipient, shares);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override whenNotPaused returns (bool) {
        require(amount <= balanceOf(sender), "ISh");
        uint256 funds = getDepositedFunds(sender);
        uint256 sharesToTokens = funds.mul(amount).div(balanceOf(sender));
        _decreaseDepositedFunds(sender, sharesToTokens);
        _traceDepositedFunds(recipient, sharesToTokens);

        return super.transferFrom(sender, recipient, amount);
    }

    /**
     * @notice Triggers an approval from owner to spends
     * @param shares The number of shares to withdraw
     * @param deadline The time at which to expire the signature
     * @param _fee The custom fee applied
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function withdraw(
        //only the owner can withdraw
        uint256 shares,
        uint256 deadline,
        uint256 _fee,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external whenNotPaused {
        verifySignatureCustomFee(shares, deadline, _fee, v, r, s);
        _withdraw(shares, _fee);
    }

    function verifySignatureCustomFee(
        uint256 shares,
        uint256 deadline,
        uint256 _fee,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view {
        require(block.timestamp <= deadline, "DE");
        feeResolver.validateFee(_fee);
        bytes32 structHash = keccak256(
            abi.encode(
                HelpersUpgradeable.getBonusTypeHash(),
                msg.sender,
                shares,
                deadline,
                _fee
            )
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        address signatory = ecrecover(digest, v, r, s);
        _verifyBonusRewarderRole(signatory);
    }

    /**
     * @notice
     *  Used to get the most recent vault for the token using the registry.
     * @return An instance of a VaultAPI
     */
    function bestVault() public view virtual returns (VaultAPI) {
        return baseRouter.bestVault(address(token));
    }

    /**
     * @notice
     *  Used to get the balance of an account accross all the vaults for a token.
     *  @dev will be used to get the wrapper balance using totalVaultBalance(address(this)).
     *  @param account The address of the account.
     *  @return balance of token for the account accross all the vaults.
     */
    function totalVaultBalance(address account) public view returns (uint256) {
        return baseRouter.totalVaultBalance(address(token), account);
    }

    /**
     * @notice
     *  Used to get the TVL on the underlying vaults.
     *  @return assets the sum of all the assets managed by the underlying vaults.
     */
    function totalAssets() public view returns (uint256) {
        return baseRouter.totalAssets(address(token));
    }

    function _deposit(
        address depositor,
        address receiver,
        uint256 amount, // if `MAX_UINT256`, just deposit everything
        bool pullFunds // If true, funds need to be pulled from `depositor` via `transferFrom`
    ) private returns (uint256) {
        return _deposit(token, depositor, receiver, amount, pullFunds);
    }

    function _withdraw(
        address sender,
        address receiver,
        uint256 amount, // if `MAX_UINT256`, just withdraw everything
        bool withdrawFromBest, // If true, also withdraw from `_bestVault`
        uint256 sharesToInvestedTokens,
        uint256 _fee,
        uint256 _thresholdMinimumFeeCollection
    ) private returns (uint256 withdrawn) {
        withdrawn = _withdrawFromVaults(
            token,
            sender,
            amount,
            withdrawFromBest
        );
        uint256 deductedTokenFees = feeResolver.determineFee(
            withdrawn,
            sharesToInvestedTokens,
            receiver,
            _fee
        );
        // `receiver` now has `withdrawn` tokens as balance
        if (receiver != address(this)) {
            withdrawn = withdrawn - deductedTokenFees;
            SafeERC20Upgradeable.safeTransfer(token, receiver, withdrawn);
        }
        bool isCollectorTriggerer = token.balanceOf(address(this)) >=
            _thresholdMinimumFeeCollection;
        emit FundsWithdrawn(
            receiver,
            deductedTokenFees,
            sharesToInvestedTokens,
            withdrawn,
            isCollectorTriggerer
        );
    }

    function _verifyContractUpdaterRole() private view {
        require(
            roles.hasRole(
                HelpersUpgradeable.getContractUpdaterRoleId(),
                msg.sender
            ),
            "UCUA"
        );
    }

    function _verifyTreasuryRole() private view {
        require(
            roles.hasRole(HelpersUpgradeable.getTreasuryRoleId(), msg.sender),
            "UTRA"
        );
    }

    function _verifyBonusRewarderRole(address signatory) private view {
        require(
            roles.hasRole(
                HelpersUpgradeable.getBonusRewarderRoleId(),
                signatory
            ),
            "UBRA"
        );
    }

    //#########################################################
    function _traceDepositedFunds(address investor, uint256 _deposited)
        private
    {
        uint256 updated = _depositedFunds[investor] + _deposited;
        require(updated >= _depositedFunds[investor], "TIO");
        _depositedFunds[investor] += _deposited;
    }

    function getDepositedFunds(address investor)
        public
        view
        returns (uint256 funds)
    {
        funds = _depositedFunds[investor];
    }

    function _decreaseDepositedFunds(address investor, uint256 amount) private {
        uint256 currentFunds = _depositedFunds[investor];
        require(currentFunds >= amount, "DIO");
        _depositedFunds[investor] -= amount;
    }

    //#######################################
    function _claimFees(IERC20Upgradeable _token, address _feeCollector)
        private
        returns (uint256 amount)
    {
        amount = _token.balanceOf(address(this));
        require(amount > 0, "NFTBC");
        SafeERC20Upgradeable.safeTransfer(_token, _feeCollector, amount);
        emit FeesCollected(msg.sender, _feeCollector, amount);
    }

    //######################################

    function _deposit(
        IERC20Upgradeable _token,
        address depositor,
        address receiver,
        uint256 amount, // if `MAX_UINT256`, just deposit everything
        bool pullFunds // If true, funds need to be pulled from `depositor` via `transferFrom`
    ) private returns (uint256 deposited) {
        baseRouter.verifyVaultExist(address(token));

        VaultAPI _bestVault = baseRouter.bestVault(address(token));

        uint256 initialBal = _token.balanceOf(address(this));
        if (pullFunds) {
            if (amount == HelpersUpgradeable.getDepositEverythingAmount()) {
                amount = _token.balanceOf(depositor);
            }
            SafeERC20Upgradeable.safeTransferFrom(
                _token,
                depositor,
                address(this),
                amount
            );
        }

        if (_token.allowance(address(this), address(_bestVault)) < amount) {
            SafeERC20Upgradeable.safeApprove(_token, address(_bestVault), 0); // Avoid issues with some _tokens requiring 0
            SafeERC20Upgradeable.safeApprove(
                _token,
                address(_bestVault),
                HelpersUpgradeable.getUnlimitedApprovalAmount()
            ); // Vaults are trusted
        }

        // Depositing returns number of shares deposited
        // NOTE: Shortcut here is assuming the number of tokens deposited is equal to the
        //       number of shares credited, which helps avoid an occasional multiplication
        //       overflow if trying to adjust the number of shares by the share price.
        uint256 beforeBal = _token.balanceOf(address(this));
        if (receiver != address(this)) {
            _bestVault.deposit(amount, receiver);
        } else if (amount != HelpersUpgradeable.getDepositEverythingAmount()) {
            _bestVault.deposit(amount);
        } else {
            _bestVault.deposit();
        }

        uint256 afterBal = _token.balanceOf(address(this));
        deposited = beforeBal.sub(afterBal);
        // `receiver` now has shares of `_bestVault` as balance, converted to `token` here
        // Issue a refund if not everything was deposited
        if (depositor != address(this) && (afterBal > initialBal)) {
            SafeERC20Upgradeable.safeTransfer(
                _token,
                depositor,
                (afterBal - initialBal)
            );
        }
    }

    function _withdrawFromVaults(
        IERC20Upgradeable _token,
        address sender,
        uint256 amount, // if `MAX_UINT256`, just withdraw everything
        bool withdrawFromBest // If true, also withdraw from `_bestVault`
    ) private returns (uint256 withdrawn) {
        require(amount > 0, "IATW");
        VaultAPI _bestVault = baseRouter.bestVault(address(_token));
        VaultAPI[] memory vaults = baseRouter.updateVaultCache(address(_token)); //allVaults(address(_token));
        //_updateVaultCache(address(_token), vaults);

        // NOTE: This loop will attempt to withdraw from each Vault in `allVaults` that `sender`
        //       is deposited in, up to `amount` tokens. The withdraw action can be expensive,
        //       so it if there is a denial of service issue in withdrawing, the downstream usage
        //       of this router contract must give an alternative method of withdrawing using
        //       this function so that `amount` is less than the full amount requested to withdraw
        //       (e.g. "piece-wise withdrawals"), leading to less loop iterations such that the
        //       DoS issue is mitigated (at a tradeoff of requiring more txns from the end user).
        for (uint256 id = 0; id < vaults.length; id++) {
            if (!withdrawFromBest && vaults[id] == _bestVault) {
                continue; // Don't withdraw from the best
            }

            // Start with the total shares that `sender` has
            uint256 availableShares = vaults[id].balanceOf(sender);

            // Restrict by the allowance that `sender` has to this contract
            // NOTE: No need for allowance check if `sender` is this contract
            if (sender != address(this)) {
                availableShares = MathUpgradeable.min(
                    availableShares,
                    vaults[id].allowance(sender, address(this))
                );
            }

            // Limit by maximum withdrawal size from each vault
            availableShares = MathUpgradeable.min(
                availableShares,
                vaults[id].maxAvailableShares()
            );

            if (availableShares > 0) {
                // Intermediate step to move shares to this contract before withdrawing
                // NOTE: No need for share transfer if this contract is `sender`

                if (
                    amount != HelpersUpgradeable.getWithdrawEverythingAmount()
                ) {
                    // amount of yield bearing assets
                    // Compute amount to withdraw fully to satisfy the request
                    uint256 estimatedShares = amount
                        .sub(withdrawn)
                        .mul(10**uint256(vaults[id].decimals()))
                        .div(vaults[id].pricePerShare()); // NOTE: Changes every iteration // NOTE: Every Vault is different

                    // Limit amount to withdraw to the maximum made available to this contract
                    // NOTE: Avoid corner case where `estimatedShares` isn't precise enough
                    // NOTE: If `0 < estimatedShares < 1` but `availableShares > 1`, this will withdraw more than necessary
                    if (
                        estimatedShares > 0 && estimatedShares < availableShares
                    ) {
                        if (sender != address(this))
                            //a case of a user/account moving funds to this contract account
                            vaults[id].transferFrom(
                                sender,
                                address(this),
                                estimatedShares
                            ); //move yv shares
                        withdrawn = withdrawn.add(
                            vaults[id].withdraw(estimatedShares)
                        ); //get the bearing tokens corresponding to the estimaded amount of shares
                    } else {
                        if (sender != address(this))
                            vaults[id].transferFrom(
                                sender,
                                address(this),
                                availableShares
                            );
                        withdrawn = withdrawn.add(
                            vaults[id].withdraw(availableShares)
                        );
                    }
                } else {
                    if (sender != address(this))
                        vaults[id].transferFrom(
                            sender,
                            address(this),
                            availableShares
                        );
                    withdrawn = withdrawn.add(vaults[id].withdraw());
                }

                // Check if we have fully satisfied the request
                // NOTE: use `amount = WITHDRAW_EVERYTHING` for withdrawing everything
                if (amount <= withdrawn) break; // withdrawn as much as we needed
            }
        }

        // If we have extra, deposit back into `_bestVault` for `sender`
        // NOTE: Invariant is `withdrawn <= amount`
        if (
            withdrawn > amount &&
            withdrawn.sub(amount) >
            _bestVault.pricePerShare().div(10**_bestVault.decimals())
        ) {
            // Don't forget to approve the deposit
            if (
                _token.allowance(address(this), address(_bestVault)) <
                withdrawn.sub(amount)
            ) {
                SafeERC20Upgradeable.safeApprove(
                    _token,
                    address(_bestVault),
                    0
                );
                SafeERC20Upgradeable.safeApprove(
                    _token,
                    address(_bestVault),
                    HelpersUpgradeable.getUnlimitedApprovalAmount()
                ); // Vaults are trusted
            }

            _bestVault.deposit(withdrawn.sub(amount), sender);
            withdrawn = amount;
        }
    }
}
