// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./Imports.sol";
import "./Imports.sol";
import "./Imports.sol";
import "./Imports.sol";
import "./Imports.sol";
import "./Imports.sol";
import "./Imports.sol";
import "./Imports.sol";

import "./ILpAccountFunder.sol";

/**
 * @notice This contract has hybrid functionality:
 *
 * - It acts as a token that tracks the capital that has been pulled
 * ("deployed") from APY Finance pools (PoolToken contracts)
 *
 * - It is permissioned to transfer funds between the pools and the
 * LP Account contract.
 *
 * @dev When MetaPoolToken pulls capital from the pools to the LP Account, it
 * will mint mAPT for each pool. Conversely, when MetaPoolToken withdraws funds
 * from the LP Account to the pools, it will burn mAPT for each pool.
 *
 * The ratio of each pool's mAPT balance to the total mAPT supply determines
 * the amount of the TVL dedicated to the pool.
 *
 *
 * DEPLOY CAPITAL TO YIELD FARMING STRATEGIES
 * Mints appropriate mAPT amount to track share of deployed TVL owned by a pool.
 *
 * +-------------+  MetaPoolToken.fundLpAccount  +-----------+
 * |             |------------------------------>|           |
 * | PoolTokenV2 |     MetaPoolToken.mint        | LpAccount |
 * |             |<------------------------------|           |
 * +-------------+                               +-----------+
 *
 *
 * WITHDRAW CAPITAL FROM YIELD FARMING STRATEGIES
 * Uses mAPT to calculate the amount of capital returned to the PoolToken.
 *
 * +-------------+  MetaPoolToken.withdrawFromLpAccount  +-----------+
 * |             |<--------------------------------------|           |
 * | PoolTokenV2 |          MetaPoolToken.burn           | LpAccount |
 * |             |-------------------------------------->|           |
 * +-------------+                                       +-----------+
 */
contract MetaPoolTokenV2 is
    Initializable,
    AccessControlUpgradeSafe,
    ReentrancyGuardUpgradeSafe,
    PausableUpgradeSafe,
    ERC20UpgradeSafe,
    ILpAccountFunder,
    Erc20AllocationConstants
{
    using AddressUpgradeSafe for address;
    using SafeMathUpgradeSafe for uint256;
    using SignedSafeMathUpgradeSafe for int256;
    using SafeERC20 for IDetailedERC20;

    uint256 public constant DEFAULT_MAPT_TO_UNDERLYER_FACTOR = 1000;

    /* ------------------------------- */
    /* impl-specific storage variables */
    /* ------------------------------- */
    /** @notice used to protect mint and burn function */
    IAddressRegistryV2 public addressRegistry;

    /* ------------------------------- */

    event Mint(address acccount, uint256 amount);
    event Burn(address acccount, uint256 amount);
    event AddressRegistryChanged(address);

    /**
     * @dev Since the proxy delegate calls to this "logic" contract, any
     * storage set by the logic contract's constructor during deploy is
     * disregarded and this function is needed to initialize the proxy
     * contract's storage according to this contract's layout.
     *
     * Since storage is not set yet, there is no simple way to protect
     * calling this function with owner modifiers.  Thus the OpenZeppelin
     * `initializer` modifier protects this function from being called
     * repeatedly.  It should be called during the deployment so that
     * it cannot be called by someone else later.
     */
    function initialize(address addressRegistry_) external initializer {
        // initialize ancestor storage
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();
        __ERC20_init_unchained("APY MetaPool Token", "mAPT");

        // initialize impl-specific storage
        _setAddressRegistry(addressRegistry_);
        _setupRole(DEFAULT_ADMIN_ROLE, addressRegistry.emergencySafeAddress());
        _setupRole(LP_ROLE, addressRegistry.lpSafeAddress());
        _setupRole(EMERGENCY_ROLE, addressRegistry.emergencySafeAddress());
    }

    /**
     * @dev Dummy function to show how one would implement an init function
     * for future upgrades.  Note the `initializer` modifier can only be used
     * once in the entire contract, so we can't use it here.  Instead, we
     * protect the upgrade init with the `onlyProxyAdmin` modifier, which
     * checks `msg.sender` against the proxy admin slot defined in EIP-1967.
     * This will only allow the proxy admin to call this function during upgrades.
     */
    // solhint-disable-next-line no-empty-blocks
    function initializeUpgrade() external virtual nonReentrant onlyProxyAdmin {}

    /**
     * @notice Sets the address registry
     * @param addressRegistry_ the address of the registry
     */
    function emergencySetAddressRegistry(address addressRegistry_)
        external
        nonReentrant
        onlyEmergencyRole
    {
        _setAddressRegistry(addressRegistry_);
    }

    function fundLpAccount(bytes32[] calldata poolIds)
        external
        override
        nonReentrant
        onlyLpRole
    {
        (IReservePool[] memory pools, int256[] memory amounts) =
            getRebalanceAmounts(poolIds);

        uint256[] memory fundAmounts = _getFundAmounts(amounts);

        _fundLpAccount(pools, fundAmounts);

        emit FundLpAccount(poolIds, fundAmounts);
    }

    function withdrawFromLpAccount(bytes32[] calldata poolIds)
        external
        override
        nonReentrant
        onlyLpRole
    {
        (IReservePool[] memory pools, int256[] memory topupAmounts) =
            getRebalanceAmounts(poolIds);

        uint256[] memory lpAccountBalances = getLpAccountBalances(poolIds);
        uint256[] memory withdrawAmounts =
            _calculateAmountsToWithdraw(topupAmounts, lpAccountBalances);

        _withdrawFromLpAccount(pools, withdrawAmounts);
        emit WithdrawFromLpAccount(poolIds, withdrawAmounts);
    }

    /**
     * @notice Get the USD-denominated value (in wei) of the pool's share
     * of the deployed capital, as tracked by the mAPT token.
     * @return The value deployed to the LP Account
     */
    function getDeployedValue(address pool) external view returns (uint256) {
        uint256 balance = balanceOf(pool);
        uint256 totalSupply = totalSupply();
        if (totalSupply == 0 || balance == 0) return 0;

        return _getTvl().mul(balance).div(totalSupply);
    }

    /**
     * @notice Returns the (signed) top-up amount for each pool ID given.
     * A positive (negative) sign means the reserve level is in deficit
     * (excess) of required percentage.
     * @param poolIds array of pool identifiers
     * @return The array of pools
     * @return An array of rebalance amounts
     */
    function getRebalanceAmounts(bytes32[] memory poolIds)
        public
        view
        returns (IReservePool[] memory, int256[] memory)
    {
        IReservePool[] memory pools = new IReservePool[](poolIds.length);
        int256[] memory rebalanceAmounts = new int256[](poolIds.length);

        for (uint256 i = 0; i < poolIds.length; i++) {
            IReservePool pool =
                IReservePool(addressRegistry.getAddress(poolIds[i]));
            int256 rebalanceAmount = pool.getReserveTopUpValue();

            pools[i] = pool;
            rebalanceAmounts[i] = rebalanceAmount;
        }

        return (pools, rebalanceAmounts);
    }

    function getLpAccountBalances(bytes32[] memory poolIds)
        public
        view
        returns (uint256[] memory)
    {
        address lpAccountAddress = addressRegistry.lpAccountAddress();
        require(lpAccountAddress != address(0), "INVALID_LP_ACCOUNT"); // defensive check -- should never happen

        uint256[] memory lpAccountBalances = new uint256[](poolIds.length);

        for (uint256 i = 0; i < poolIds.length; i++) {
            IReservePool pool =
                IReservePool(addressRegistry.getAddress(poolIds[i]));
            IDetailedERC20 underlyer = IDetailedERC20(pool.underlyer());

            lpAccountBalances[i] = underlyer.balanceOf(lpAccountAddress);
        }

        return lpAccountBalances;
    }

    function _setAddressRegistry(address addressRegistry_) internal {
        require(addressRegistry_.isContract(), "INVALID_ADDRESS");
        addressRegistry = IAddressRegistryV2(addressRegistry_);
        emit AddressRegistryChanged(addressRegistry_);
    }

    function _fundLpAccount(
        IReservePool[] memory pools,
        uint256[] memory amounts
    ) internal {
        address lpAccountAddress = addressRegistry.lpAccountAddress();
        require(lpAccountAddress != address(0), "INVALID_LP_ACCOUNT"); // defensive check -- should never happen

        _multipleMintAndTransfer(pools, amounts);
        _registerPoolUnderlyers(pools);
    }

    function _multipleMintAndTransfer(
        IReservePool[] memory pools,
        uint256[] memory amounts
    ) internal {
        uint256[] memory deltas = _calculateDeltas(pools, amounts);

        // MUST do the actual minting after calculating *all* mint amounts,
        // otherwise due to Chainlink not updating during a transaction,
        // the totalSupply will change while TVL doesn't.
        //
        // Using the pre-mint TVL and totalSupply gives the same answer
        // as using post-mint values.
        for (uint256 i = 0; i < pools.length; i++) {
            IReservePool pool = pools[i];
            uint256 mintAmount = deltas[i];
            uint256 transferAmount = amounts[i];
            _mintAndTransfer(pool, mintAmount, transferAmount);
        }

        ILockingOracle oracleAdapter = _getOracleAdapter();
        oracleAdapter.lock();
    }

    function _mintAndTransfer(
        IReservePool pool,
        uint256 mintAmount,
        uint256 transferAmount
    ) internal {
        if (mintAmount == 0) {
            return;
        }
        _mint(address(pool), mintAmount);
        pool.transferToLpAccount(transferAmount);
        emit Mint(address(pool), mintAmount);
    }

    /**
     * @dev Transfer the specified amounts to pools, doing mAPT burns,
     * and checking the transferred tokens have been registered.
     */
    function _withdrawFromLpAccount(
        IReservePool[] memory pools,
        uint256[] memory amounts
    ) internal {
        address lpAccountAddress = addressRegistry.lpAccountAddress();
        require(lpAccountAddress != address(0), "INVALID_LP_ACCOUNT"); // defensive check -- should never happen

        _multipleBurnAndTransfer(pools, amounts);
        _registerPoolUnderlyers(pools);
    }

    function _multipleBurnAndTransfer(
        IReservePool[] memory pools,
        uint256[] memory amounts
    ) internal {
        address lpAccount = addressRegistry.lpAccountAddress();
        require(lpAccount != address(0), "INVALID_LP_ACCOUNT"); // defensive check -- should never happen

        uint256[] memory deltas = _calculateDeltas(pools, amounts);

        // MUST do the actual burning after calculating *all* burn amounts,
        // otherwise due to Chainlink not updating during a transaction,
        // the totalSupply will change while TVL doesn't.
        //
        // Using the pre-burn TVL and totalSupply gives the same answer
        // as using post-burn values.
        for (uint256 i = 0; i < pools.length; i++) {
            IReservePool pool = pools[i];
            uint256 burnAmount = deltas[i];
            uint256 transferAmount = amounts[i];
            _burnAndTransfer(pool, lpAccount, burnAmount, transferAmount);
        }

        ILockingOracle oracleAdapter = _getOracleAdapter();
        oracleAdapter.lock();
    }

    function _burnAndTransfer(
        IReservePool pool,
        address lpAccount,
        uint256 burnAmount,
        uint256 transferAmount
    ) internal {
        if (burnAmount == 0) {
            return;
        }
        _burn(address(pool), burnAmount);
        ILpAccount(lpAccount).transferToPool(address(pool), transferAmount);
        emit Burn(address(pool), burnAmount);
    }

    /**
     * @notice Register an asset allocation for the account with each pool underlyer
     * @param pools list of pool amounts whose pool underlyers will be registered
     */
    function _registerPoolUnderlyers(IReservePool[] memory pools) internal {
        IAssetAllocationRegistry tvlManager =
            IAssetAllocationRegistry(addressRegistry.getAddress("tvlManager"));
        IErc20Allocation erc20Allocation =
            IErc20Allocation(
                address(
                    tvlManager.getAssetAllocation(Erc20AllocationConstants.NAME)
                )
            );

        for (uint256 i = 0; i < pools.length; i++) {
            IDetailedERC20 underlyer =
                IDetailedERC20(address(pools[i].underlyer()));

            if (!erc20Allocation.isErc20TokenRegistered(underlyer)) {
                erc20Allocation.registerErc20Token(underlyer);
            }
        }
    }

    /**
     * @notice Get the USD value of all assets in the system, not just those
     * being managed by the AccountManager but also the pool underlyers.
     *
     * Note this is NOT the same as the total value represented by the
     * total mAPT supply, i.e. the "deployed capital".
     *
     * @dev Chainlink nodes read from the TVLManager, pull the
     * prices from market feeds, and submits the calculated total value
     * to an aggregator contract.
     *
     * USD prices have 8 decimals.
     *
     * @return "Total Value Locked", the USD value of all APY Finance assets.
     */
    function _getTvl() internal view returns (uint256) {
        ILockingOracle oracleAdapter = _getOracleAdapter();
        return oracleAdapter.getTvl();
    }

    function _getOracleAdapter() internal view returns (ILockingOracle) {
        address oracleAdapterAddress = addressRegistry.oracleAdapterAddress();
        return ILockingOracle(oracleAdapterAddress);
    }

    function _calculateDeltas(
        IReservePool[] memory pools,
        uint256[] memory amounts
    ) internal view returns (uint256[] memory) {
        require(pools.length == amounts.length, "LENGTHS_MUST_MATCH");
        uint256[] memory deltas = new uint256[](pools.length);

        for (uint256 i = 0; i < pools.length; i++) {
            IReservePool pool = pools[i];
            uint256 amount = amounts[i];

            IDetailedERC20 underlyer = pool.underlyer();
            uint256 tokenPrice = pool.getUnderlyerPrice();
            uint8 decimals = underlyer.decimals();

            deltas[i] = _calculateDelta(amount, tokenPrice, decimals);
        }

        return deltas;
    }

    /**
     * @notice Calculate mAPT amount for given pool's underlyer amount.
     * @param amount Pool underlyer amount to be converted
     * @param tokenPrice Pool underlyer's USD price (in wei) per underlyer token
     * @param decimals Pool underlyer's number of decimals
     * @dev Price parameter is in units of wei per token ("big" unit), since
     * attempting to express wei per token bit ("small" unit) will be
     * fractional, requiring fixed-point representation.  This means we need
     * to also pass in the underlyer's number of decimals to do the appropriate
     * multiplication in the calculation.
     * @dev amount of APT minted should be in same ratio to APT supply
     * as deposit value is to pool's total value, i.e.:
     *
     * mint amount / total supply
     * = deposit value / pool total value
     *
     * For denominators, pre or post-deposit amounts can be used.
     * The important thing is they are consistent, i.e. both pre-deposit
     * or both post-deposit.
     */
    function _calculateDelta(
        uint256 amount,
        uint256 tokenPrice,
        uint8 decimals
    ) internal view returns (uint256) {
        uint256 value = amount.mul(tokenPrice).div(10**uint256(decimals));
        uint256 totalValue = _getTvl();
        uint256 totalSupply = totalSupply();

        if (totalValue == 0 || totalSupply == 0) {
            return value.mul(DEFAULT_MAPT_TO_UNDERLYER_FACTOR);
        }

        return value.mul(totalSupply).div(totalValue);
    }

    function _getFundAmounts(int256[] memory amounts)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory fundAmounts = new uint256[](amounts.length);

        for (uint256 i = 0; i < amounts.length; i++) {
            int256 amount = amounts[i];

            fundAmounts[i] = amount < 0 ? uint256(-amount) : 0;
        }

        return fundAmounts;
    }

    /**
     * @dev Calculate amounts used for topup, taking into
     * account the available LP Account balances.
     */
    function _calculateAmountsToWithdraw(
        int256[] memory topupAmounts,
        uint256[] memory lpAccountBalances
    ) internal pure returns (uint256[] memory) {
        uint256[] memory withdrawAmounts = new uint256[](topupAmounts.length);
        for (uint256 i = 0; i < topupAmounts.length; i++) {
            int256 topupAmount = topupAmounts[i];

            uint256 withdrawAmount = topupAmount > 0 ? uint256(topupAmount) : 0;
            uint256 lpAccountBalance = lpAccountBalances[i];
            withdrawAmounts[i] = withdrawAmount > lpAccountBalance
                ? lpAccountBalance
                : withdrawAmount;
        }

        return withdrawAmounts;
    }
}
