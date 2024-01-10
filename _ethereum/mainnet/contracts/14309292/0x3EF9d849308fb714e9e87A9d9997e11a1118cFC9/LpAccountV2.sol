// SPDX-License-Identifier: BUSDL-1.1
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

contract LpAccountV2 is
    Initializable,
    AccessControlUpgradeSafe,
    ReentrancyGuardUpgradeSafe,
    ILpAccountV2,
    IZapRegistry,
    ISwapRegistry,
    Erc20AllocationConstants,
    IEmergencyExit,
    IRewardFeeRegistry
{
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using NamedAddressSet for NamedAddressSet.ZapSet;
    using NamedAddressSet for NamedAddressSet.SwapSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    IStableSwap3Pool private constant _STABLE_SWAP_3POOL =
        IStableSwap3Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    uint256 private constant _DEFAULT_LOCK_PERIOD = 135;

    /**
     * Begin storage variables
     */

    /** V1 storage */

    IAddressRegistryV2 public addressRegistry;
    uint256 public lockPeriod;

    NamedAddressSet.ZapSet private _zaps;
    NamedAddressSet.SwapSet private _swaps;

    /** V2 storage */

    /** @dev reward tokens to deduct fees on claim */
    EnumerableSet.AddressSet private _rewardTokens;
    /** @dev reward token fees in basis points */
    mapping(address => uint256) public rewardFee;

    /**
     * End storage variables
     */

    /** @notice Log when the address registry is changed */
    event AddressRegistryChanged(address);

    /** @notice Log when the lock period is changed */
    event LockPeriodChanged(uint256);

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

        // initialize impl-specific storage
        _setAddressRegistry(addressRegistry_);
        _setupRole(DEFAULT_ADMIN_ROLE, addressRegistry.emergencySafeAddress());
        _setupRole(EMERGENCY_ROLE, addressRegistry.emergencySafeAddress());
        _setupRole(ADMIN_ROLE, addressRegistry.adminSafeAddress());
        _setupRole(LP_ROLE, addressRegistry.lpSafeAddress());
        _setupRole(CONTRACT_ROLE, addressRegistry.mAptAddress());

        lockPeriod = _DEFAULT_LOCK_PERIOD;
    }

    /**
     * @dev Note the `initializer` modifier can only be used once in the entire
     * contract, so we can't use it here.  Instead, we protect the upgrade init
     * with the `onlyProxyAdmin` modifier, which checks `msg.sender` against the
     * proxy admin slot defined in EIP-1967. This will only allow the proxy admin
     * to call this function during upgrades.
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

    /**
     * @notice Set the lock period
     * @param lockPeriod_ The new lock period
     */
    function setLockPeriod(uint256 lockPeriod_)
        external
        nonReentrant
        onlyAdminRole
    {
        lockPeriod = lockPeriod_;
        emit LockPeriodChanged(lockPeriod_);
    }

    function deployStrategy(string calldata name, uint256[] calldata amounts)
        external
        override
        nonReentrant
        onlyLpRole
    {
        IZap zap = _zaps.get(name);
        require(address(zap) != address(0), "INVALID_NAME");

        bool isAssetAllocationRegistered =
            _checkAllocationRegistrations(zap.assetAllocations());
        require(isAssetAllocationRegistered, "MISSING_ASSET_ALLOCATIONS");

        bool isErc20TokenRegistered =
            _checkErc20Registrations(zap.erc20Allocations());
        require(isErc20TokenRegistered, "MISSING_ERC20_ALLOCATIONS");

        address(zap).functionDelegateCall(
            abi.encodeWithSelector(IZap.deployLiquidity.selector, amounts)
        );
        _lockOracleAdapter(lockPeriod);
    }

    function unwindStrategy(
        string calldata name,
        uint256 amount,
        uint8 index
    ) external override nonReentrant onlyLpRole {
        address zap = address(_zaps.get(name));
        require(zap != address(0), "INVALID_NAME");
        zap.functionDelegateCall(
            abi.encodeWithSelector(IZap.unwindLiquidity.selector, amount, index)
        );
        _lockOracleAdapter(lockPeriod);
    }

    function registerZap(IZap zap)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        _zaps.add(zap);

        emit ZapRegistered(zap);
    }

    function removeZap(string calldata name)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        _zaps.remove(name);

        emit ZapRemoved(name);
    }

    function transferToPool(address pool, uint256 amount)
        external
        override
        nonReentrant
        onlyContractRole
    {
        IERC20 underlyer = ILiquidityPoolV2(pool).underlyer();
        underlyer.safeTransfer(pool, amount);
    }

    function swap(
        string calldata name,
        uint256 amount,
        uint256 minAmount
    ) external override nonReentrant onlyLpRole {
        ISwap swap_ = _swaps.get(name);
        require(address(swap_) != address(0), "INVALID_NAME");

        bool isErc20TokenRegistered =
            _checkErc20Registrations(swap_.erc20Allocations());

        require(isErc20TokenRegistered, "MISSING_ERC20_ALLOCATIONS");

        address(swap_).functionDelegateCall(
            abi.encodeWithSelector(ISwap.swap.selector, amount, minAmount)
        );
        _lockOracleAdapter(lockPeriod);
    }

    function registerSwap(ISwap swap_)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        _swaps.add(swap_);

        emit SwapRegistered(swap_);
    }

    function removeSwap(string calldata name)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        _swaps.remove(name);

        emit SwapRemoved(name);
    }

    /**
     * @notice Swap stablecoins with the Curve 3pool
     * @param inTokenIndex Token index for the input token
     * @param outTokenIndex Token index for the output token
     * @param amount The amount of token to swap
     * @param minAmount The minimum amount of output token to receive
     */
    function swapWith3Pool(
        int128 inTokenIndex,
        int128 outTokenIndex,
        uint256 amount,
        uint256 minAmount
    ) external nonReentrant onlyLpRole {
        IERC20 inToken =
            IERC20(_STABLE_SWAP_3POOL.coins(uint256(inTokenIndex)));

        inToken.safeApprove(address(_STABLE_SWAP_3POOL), 0);
        inToken.safeApprove(address(_STABLE_SWAP_3POOL), amount);

        _STABLE_SWAP_3POOL.exchange(
            inTokenIndex,
            outTokenIndex,
            amount,
            minAmount
        );

        _lockOracleAdapter(lockPeriod);
    }

    function claim(string[] calldata names)
        external
        override
        nonReentrant
        onlyLpRole
    {
        uint256[] memory preClaimRewardsBalances = _getRewardsBalances();

        for (uint256 i = 0; i < names.length; i++) {
            string calldata name = names[i];
            IZap zap = _zaps.get(name);
            require(address(zap) != address(0), "INVALID_NAME");

            bool isErc20TokenRegistered =
                _checkErc20Registrations(zap.erc20Allocations());
            require(isErc20TokenRegistered, "MISSING_ERC20_ALLOCATIONS");

            address(zap).functionDelegateCall(
                abi.encodeWithSelector(IZap.claim.selector)
            );
        }

        uint256[] memory postClaimRewardsBalances = _getRewardsBalances();
        uint256[] memory rewardsFees =
            _calculateRewardsFees(
                preClaimRewardsBalances,
                postClaimRewardsBalances
            );
        _sendFeesToTreasurySafe(rewardsFees);

        _lockOracleAdapter(lockPeriod);
    }

    function registerRewardFee(address token, uint256 fee)
        external
        override
        onlyAdminRole
    {
        _registerRewardFee(token, fee);
    }

    function registerMultipleRewardFees(
        address[] calldata tokens,
        uint256[] calldata fees
    ) external override onlyAdminRole {
        require(tokens.length == fees.length, "INPUT_ARRAYS_MISMATCH");
        for (uint256 i = 0; i < tokens.length; i++) {
            _registerRewardFee(tokens[i], fees[i]);
        }
    }

    function removeRewardFee(address token) external override onlyAdminRole {
        _removeRewardFee(token);
    }

    function removeMultipleRewardFees(address[] calldata tokens)
        external
        override
        onlyAdminRole
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            _removeRewardFee(tokens[i]);
        }
    }

    function emergencyExit(address token) external override onlyEmergencyRole {
        address emergencySafe = addressRegistry.emergencySafeAddress();
        IERC20 token_ = IERC20(token);
        uint256 balance = token_.balanceOf(address(this));
        token_.safeTransfer(emergencySafe, balance);

        emit EmergencyExit(emergencySafe, token_, balance);
    }

    function getLpTokenBalance(string calldata name)
        external
        view
        returns (uint256 value)
    {
        address zap = address(_zaps.get(name));
        require(zap != address(0), "INVALID_NAME");
        bytes memory data =
            zap.functionStaticCall(
                abi.encodeWithSelector(
                    IZap.getLpTokenBalance.selector,
                    address(this)
                )
            );
        // Convert bytes to uint256
        assembly {
            value := mload(add(data, 0x20))
        }
    }

    function zapNames() external view override returns (string[] memory) {
        return _zaps.names();
    }

    function swapNames() external view override returns (string[] memory) {
        return _swaps.names();
    }

    /**
     * @notice Lock oracle adapter for the configured period
     * @param lockPeriod_ The number of blocks to lock for
     */
    function _lockOracleAdapter(uint256 lockPeriod_) internal {
        ILockingOracle oracleAdapter =
            ILockingOracle(addressRegistry.oracleAdapterAddress());
        // solhint-disable no-empty-blocks
        try oracleAdapter.lockFor(lockPeriod_) {} catch Error(
            string memory reason
        ) {
            // Silence the revert in the case when Oracle Adapter is already
            // locked but with longer period.  In other cases, bubble
            // up the revert.
            require(
                keccak256(bytes(reason)) ==
                    keccak256(bytes("CANNOT_SHORTEN_LOCK")),
                reason
            );
        } catch (bytes memory) {
            revert("UNKNOWN_REASON");
        }
        // solhint-enable no-empty-blocks
    }

    function _setAddressRegistry(address addressRegistry_) internal {
        require(Address.isContract(addressRegistry_), "INVALID_ADDRESS");
        addressRegistry = IAddressRegistryV2(addressRegistry_);
        emit AddressRegistryChanged(addressRegistry_);
    }

    function _registerRewardFee(address token, uint256 fee) internal {
        require(Address.isContract(token), "INVALID_ADDRESS");
        require(fee != 0, "INVALID_REWARD_FEE");
        _rewardTokens.add(token);
        rewardFee[token] = fee;

        emit RewardFeeRegistered(token, fee);
    }

    function _removeRewardFee(address token) internal {
        _rewardTokens.remove(token);
        rewardFee[token] = 0;

        emit RewardFeeRemoved(token);
    }

    function _sendFeesToTreasurySafe(uint256[] memory rewardsFees) internal {
        require(
            _rewardTokens.length() == rewardsFees.length,
            "FEE_LENGTH_MISMATCH"
        );
        address treasurySafeAddress =
            addressRegistry.getAddress("treasurySafe");
        for (uint256 i = 0; i < _rewardTokens.length(); i++) {
            if (rewardsFees[i] > 0) {
                address tokenAddress = _rewardTokens.at(i);
                IERC20(tokenAddress).safeTransfer(
                    treasurySafeAddress,
                    rewardsFees[i]
                );
            }
        }
    }

    /**
     * @notice Check if multiple asset allocations are ALL registered
     * @param allocationNames An array of asset allocation names to check
     * @return `true` if every asset allocation is registered, otherwise `false`
     */
    function _checkAllocationRegistrations(string[] memory allocationNames)
        internal
        view
        returns (bool)
    {
        IAssetAllocationRegistry tvlManager =
            IAssetAllocationRegistry(addressRegistry.getAddress("tvlManager"));

        return tvlManager.isAssetAllocationRegistered(allocationNames);
    }

    /**
     * @notice Check if multiple ERC20 asset allocations are ALL registered
     * @param tokens An array of ERC20 tokens to check
     * @return `true` if every ERC20 is registered, otherwise `false`
     */
    function _checkErc20Registrations(IERC20[] memory tokens)
        internal
        view
        returns (bool)
    {
        IAssetAllocationRegistry tvlManager =
            IAssetAllocationRegistry(addressRegistry.getAddress("tvlManager"));
        IErc20Allocation erc20Allocation =
            IErc20Allocation(
                address(
                    tvlManager.getAssetAllocation(Erc20AllocationConstants.NAME)
                )
            );

        return erc20Allocation.isErc20TokenRegistered(tokens);
    }

    function _getRewardsBalances()
        internal
        view
        returns (uint256[] memory balances)
    {
        balances = new uint256[](_rewardTokens.length());
        for (uint256 i = 0; i < _rewardTokens.length(); i++) {
            address tokenAddress = _rewardTokens.at(i);
            balances[i] = IERC20(tokenAddress).balanceOf(address(this));
        }
    }

    function _calculateRewardsFees(
        uint256[] memory preClaimRewardsBalances,
        uint256[] memory postClaimRewardsBalances
    ) internal view returns (uint256[] memory rewardsFees) {
        require(
            preClaimRewardsBalances.length == postClaimRewardsBalances.length,
            "INPUT_ARRAYS_MISMATCH"
        );
        require(
            _rewardTokens.length() == preClaimRewardsBalances.length,
            "BALANCE_LENGTH_MISMATCH"
        );
        rewardsFees = new uint256[](_rewardTokens.length());
        for (uint256 i = 0; i < _rewardTokens.length(); i++) {
            uint256 balanceDelta =
                postClaimRewardsBalances[i].sub(preClaimRewardsBalances[i]);
            if (balanceDelta > 0) {
                address tokenAddress = _rewardTokens.at(i);
                uint256 fee = rewardFee[tokenAddress];
                rewardsFees[i] = balanceDelta.mul(fee).div(10000);
            }
        }
    }
}
