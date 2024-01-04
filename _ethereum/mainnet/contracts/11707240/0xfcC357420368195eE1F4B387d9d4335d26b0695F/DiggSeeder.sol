// Dependency file: /Users/present/code/super-sett/deps/@openzeppelin/contracts-upgradeable/proxy/Initializable.sol

// SPDX-License-Identifier: MIT

// pragma solidity >=0.4.24 <0.7.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}


// Dependency file: /Users/present/code/super-sett/deps/@openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol


// pragma solidity ^0.6.0;
// import "./Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


// Dependency file: /Users/present/code/super-sett/deps/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// pragma solidity ^0.6.0;

// import "./ContextUpgradeable.sol";
// import "./Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}


// Dependency file: /Users/present/code/super-sett/interfaces/badger/IBadgerGeyser.sol


// pragma solidity >=0.5.0 <0.8.0;

interface IBadgerGeyser {
    function stake(address) external returns (uint256);

    function signalTokenLock(
        address token,
        uint256 amount,
        uint256 durationSec,
        uint256 startTime
    ) external;
}


// Dependency file: /Users/present/code/super-sett/interfaces/badger/IAccessControl.sol

// pragma solidity >=0.5.0 <0.8.0;

interface IAccessControl {
    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;
    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}


// Dependency file: /Users/present/code/super-sett/interfaces/uniswap/IStakingRewards.sol

// pragma solidity >=0.5.0 <0.8.0;

interface IStakingRewards {
    function stakingToken() external view returns (address);

    function rewardsToken() external view returns (address);

    function withdraw(uint256) external;

    function getReward() external;

    function earned(address account) external view returns (uint256);

    function stake(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function exit() external;

    function notifyRewardAmount(uint256 startTimestamp, uint256 reward) external;

    function setRewardsDuration(uint256 _rewardsDuration) external;
}


// Dependency file: /Users/present/code/super-sett/interfaces/uniswap/IUniswapRouterV2.sol

// pragma solidity >=0.5.0 <0.8.0;

interface IUniswapRouterV2 {
    function factory() external view returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}


// Dependency file: /Users/present/code/super-sett/interfaces/badger/IPausable.sol

// pragma solidity >=0.5.0 <0.8.0;

interface IPausable {
    function pause() external;
    function unpause() external;
}


// Dependency file: /Users/present/code/super-sett/interfaces/badger/IOwnable.sol

// pragma solidity >=0.5.0 <0.8.0;
interface IOwnable {
    function transferOwnership(address newOwner) external;
}


// Dependency file: /Users/present/code/super-sett/interfaces/digg/IDiggDistributor.sol

// pragma solidity >=0.5.0 <0.8.0;

interface IDiggDistributor {
    
    function rewardsEscrow() external view returns (address);
    function reclaimAllowedTimestamp() external view returns (uint256);
    function isOpen() external view returns (bool);

    function claim(
        uint256 index,
        address account,
        uint256 shares,
        bytes32[] calldata merkleProof
    ) external;

    /// ===== Gated Actions: Owner =====

    /// @notice Transfer unclaimed funds to rewards escrow
    function reclaim() external;

    function pause() external;

    function unpause() external;
    
    function openAirdrop() external;

}


// Dependency file: /Users/present/code/super-sett/interfaces/digg/IDigg.sol

// pragma solidity >=0.5.0 <0.8.0;

interface IDigg {
    // Used for authentication
    function monetaryPolicy() external view returns (address);

    function rebaseStartTime() external view returns (uint256);

    /**
     * @param monetaryPolicy_ The address of the monetary policy contract to use for authentication.
     */
    function setMonetaryPolicy(address monetaryPolicy_) external;

    /**
     * @dev Notifies Fragments contract about a new rebase cycle.
     * @param supplyDelta The number of new fragment tokens to add into circulation via expansion.
     * @return The total number of fragments after the supply adjustment.
     */
    function rebase(uint256 epoch, int256 supplyDelta) external returns (uint256);

    /**
     * @return The total number of fragments.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @return The total number of underlying shares.
     */
    function totalShares() external view returns (uint256);

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who) external view returns (uint256);

    /**
     * @param who The address to query.
     * @return The underlying shares of the specified address.
     */
    function sharesOf(address who) external view returns (uint256);

    /**
     * @param fragments Fragment value to convert.
     * @return The underlying share value of the specified fragment amount.
     */
    function fragmentsToShares(uint256 fragments) external view returns (uint256);

    /**
     * @param shares Share value to convert.
     * @return The current fragment value of the specified underlying share amount.
     */
    function sharesToFragments(uint256 shares) external view returns (uint256);

    function scaledSharesToShares(uint256 fragments) external view returns (uint256);
    function sharesToScaledShares(uint256 shares) external view returns (uint256);

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender) external view returns (uint256);

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}


// Dependency file: /Users/present/code/super-sett/interfaces/digg/IDiggRewardsFaucet.sol

// pragma solidity >=0.5.0 <0.8.0;

interface IDiggRewardsFaucet {
    /* ========== VIEWS ========== */

    function lastTimeRewardApplicable() external view returns (uint256);

    function earned() external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */
    function getReward() external;

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @dev Update the reward distribution schedule
    /// @dev Only callable by admin
    /// @param startTimestamp Timestamp to start distribution. If in the past, all "previously" distributed rewards within the range will be immediately claimable.
    /// @param duration Duration over which to distribute the DIGG Shares.
    /// @param rewardInShares Number of DIGG Shares to distribute within the specified time.
    function notifyRewardAmount(uint256 startTimestamp, uint256 duration, uint256 rewardInShares) external;

    function initializeRecipient(address _recipient) external;

    function pause() external;

    function unpause() external;
}

// Root file: contracts/badger-hunt/DiggSeeder.sol

// SP-License-upgradeable-Identifier: UNLICENSED
pragma solidity ^0.6.11;

// import "./OwnableUpgradeable.sol";
// import "./IBadgerGeyser.sol";
// import "./IAccessControl.sol";
// import "./IStakingRewards.sol";
// import "./IUniswapRouterV2.sol";
// import "./IPausable.sol";
// import "./IOwnable.sol";
// import "./IDiggDistributor.sol";
// import "./IDigg.sol";
// import "./IDiggRewardsFaucet.sol";

/* ===== DiggSeeder =====
Atomically initialize DIGG
    * Set all predefined unlock schedules, starting at current time
    * Seed Uni and Sushi liquidity pools
    * Unpause airdrop
*/
contract DiggSeeder is OwnableUpgradeable {
    address constant devMultisig = 0xB65cef03b9B89f99517643226d76e286ee999e77;
    address constant rewardsEscrow = 0x19d099670a21bC0a8211a89B84cEdF59AbB4377F;
    address constant daoDiggTimelock = 0x5A54Ca44e8F5A1A695f8621f15Bfa159a140bB61;
    address constant teamVesting = 0x124FD4A9bd4914b32c77C9AE51819b1181dbb3D4;
    address public airdrop;

    address constant uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant sushiRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address constant digg = 0x798D1bE841a82a273720CE31c822C61a67a601C3;
    address constant wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant badger = 0x3472A5A71965499acd81997a54BBA8D852C6E53d;
    address constant badgerTree = 0x660802Fc641b154aBA66a62137e71f331B6d787A;

    address constant native_uniBadgerWbtc_geyser = 0xA207D69Ea6Fb967E54baA8639c408c31767Ba62D;
    address constant native_sushiBadgerWbtc_geyser = 0xB5b654efBA23596Ed49FAdE44F7e67E23D6712e7;
    address constant native_badger_geyser = 0xa9429271a28F8543eFFfa136994c0839E7d7bF77;
    address constant native_renCrv_geyser = 0x2296f174374508278DC12b806A7f27c87D53Ca15;
    address constant native_sbtcCrv_geyser = 0x10fC82867013fCe1bD624FafC719Bb92Df3172FC;
    address constant native_tbtcCrv_geyser = 0x085A9340ff7692Ab6703F17aB5FfC917B580a6FD;
    address constant harvest_renCrv_geyser = 0xeD0B7f5d9F6286d00763b0FFCbA886D8f9d56d5e;
    address constant native_sushiWbtcEth_geyser = 0x612f681BCd12A0b284518D42D2DBcC73B146eb65;
    address constant native_uniDiggWbtc_geyser = 0x0194B5fe9aB7e0C43a08aCbb771516fc057402e7;
    address constant native_sushiDiggWbtc_geyser = 0x7F6FE274e172AC7d096A7b214c78584D99ca988B;

    address constant native_sushiWbtcEth_digg_faucet = 0xec48D3eD49432FFE64f39b6EB559d0fa7AC9cc90;
    address constant native_uniDiggWbtc_digg_faucet = 0xB45e51485ff078E85D9fF29c3AC0CbD9351cEBb1;
    address constant native_sushiDiggWbtc_digg_faucet = 0xF2E434772FC12705E823B2683703ee6cd8d19744;

    // ===== Initial DIGG Emissions =====
    uint256 constant native_uniBadgerWbtc_fragments = 13960000000;
    uint256 constant native_sushiBadgerWbtc_fragments = 13960000000;
    uint256 constant native_badger_fragments = 6980000000;
    uint256 constant native_renCrv_fragments = 10920000000;
    uint256 constant native_sbtcCrv_fragments = 10920000000;
    uint256 constant native_tbtcCrv_fragments = 10920000000;
    uint256 constant harvest_renCrv_fragments = 10920000000;
    uint256 constant native_sushiWbtcEth_fragments = 10920000000;

    uint256 constant native_uniDiggWbtc_fragments = 32600000000;
    uint256 constant native_sushiDiggWbtc_fragments = 32600000000;

    // Note: Native DIGG emissions are only released via DiggFaucet
    uint256 constant native_digg_fragments = 16300000000;

    // ===== Initial Badger Emissions =====
    uint256 constant native_uniBadgerWbtc_badger_emissions = 28775 ether;
    uint256 constant native_sushiBadgerWbtc_badger_emissions = 28775 ether;
    uint256 constant native_badger_badger_emissions = 14387 ether;
    uint256 constant native_renCrv_badger_emissions = 22503 ether;
    uint256 constant native_sbtcCrv_badger_emissions = 22503 ether;
    uint256 constant native_tbtcCrv_badger_emissions = 22503 ether;
    uint256 constant harvest_renCrv_badger_emissions = 22503 ether;
    uint256 constant native_sushiWbtcEth_badger_emissions = 22503 ether;

    uint256 constant initial_liquidity_wbtc = 100000000;
    uint256 constant initial_liquidity_digg = 1000000000;

    uint256 constant initial_tree_digg_supply = 23282857143; // 2 days worth of emissions to start, 81.49 a week, rounded up

    uint256 constant DIGG_TOTAL_SUPPLY = 4000000000000;
    uint256 constant LIQUIDITY_MINING_SUPPLY = (DIGG_TOTAL_SUPPLY * 40) / 100;
    uint256 constant DAO_TREASURY_SUPPLY = (DIGG_TOTAL_SUPPLY * 40) / 100;
    uint256 constant TEAM_VESTING_SUPPLY = (DIGG_TOTAL_SUPPLY * 5) / 100;
    uint256 constant AIRDROP_SUPPLY = (DIGG_TOTAL_SUPPLY * 15) / 100;

    uint256 constant badger_next_schedule_start = 1611424800;

    uint256 constant duration = 6 days;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant TOKEN_LOCKER_ROLE = keccak256("TOKEN_LOCKER_ROLE");

    bool public seeded;

    function initialize(address airdrop_) public initializer {
        __Ownable_init();
        airdrop = airdrop_;
    }

    function preSeed() external onlyOwner {
        // airdrop_pct = 15% - initial test accounts
        require(IDigg(digg).transfer(airdrop, AIRDROP_SUPPLY - 4000000000), "transfer airdrop");
        require(IDigg(digg).balanceOf(airdrop) > AIRDROP_SUPPLY - 4000000000, "AIRDROP_SUPPLY");
        require(IDiggDistributor(airdrop).isOpen() == false, "airdrop open");
    }

    function seed() external onlyOwner {
        require(seeded == false, "Already Seeded");
        // ===== Configure Emissions Schedules =====
        /*
            All DIGG Schedules are denominated in Shares
        */

        address[10] memory geysers =
            [
                native_uniBadgerWbtc_geyser,
                native_sushiBadgerWbtc_geyser,
                native_badger_geyser,
                native_renCrv_geyser,
                native_sbtcCrv_geyser,
                native_tbtcCrv_geyser,
                harvest_renCrv_geyser,
                native_sushiWbtcEth_geyser,
                native_uniDiggWbtc_geyser,
                native_sushiDiggWbtc_geyser
            ];

        uint256[10] memory digg_emissions =
            [
                native_uniBadgerWbtc_fragments,
                native_sushiBadgerWbtc_fragments,
                native_badger_fragments,
                native_renCrv_fragments,
                native_sbtcCrv_fragments,
                native_tbtcCrv_fragments,
                harvest_renCrv_fragments,
                native_sushiWbtcEth_fragments,
                native_uniDiggWbtc_fragments,
                native_sushiDiggWbtc_fragments
            ];

        uint256[10] memory badger_emissions =
            [
                native_uniBadgerWbtc_badger_emissions,
                native_sushiBadgerWbtc_badger_emissions,
                native_badger_badger_emissions,
                native_renCrv_badger_emissions,
                native_sbtcCrv_badger_emissions,
                native_tbtcCrv_badger_emissions,
                harvest_renCrv_badger_emissions,
                native_sushiWbtcEth_badger_emissions,
                0,
                0
            ];

        for (uint256 i = 0; i < geysers.length; i++) {
            IBadgerGeyser geyser = IBadgerGeyser(geysers[i]);

            // ===== DIGG Geyser Emissions =====
            // Note: native_uniDiggWbtc & native_sushiDiggWbtc distribute half of DIGG emissions through DiggFaucet
            if (i == 8 || i == 9) {
                geyser.signalTokenLock(digg, IDigg(digg).fragmentsToShares(digg_emissions[i] / 2), duration, now);
            } else {
                geyser.signalTokenLock(digg, IDigg(digg).fragmentsToShares(digg_emissions[i]), duration, now);
            }

            // ===== BADGER Geyser Emissions =====
            // native_uniBadgerWbtc & native_sushiBadgerWbtc & native_badger distribute half of BADGER emissions through StakingRewards
            if (i == 0 || i == 1 || i == 2) {
                geyser.signalTokenLock(badger, badger_emissions[i] / 2, duration, badger_next_schedule_start);
            } else if (i == 8 || i == 9) {
                // Note: native_uniDiggWbtc & native_sushiDiggWbtc have no badger schedule
            } else {
                geyser.signalTokenLock(badger, badger_emissions[i], duration, badger_next_schedule_start);
            }

            IAccessControl(address(geyser)).renounceRole(TOKEN_LOCKER_ROLE, address(this));
        }

        address[3] memory faucets = [native_sushiWbtcEth_digg_faucet, native_uniDiggWbtc_digg_faucet, native_sushiDiggWbtc_digg_faucet];
        uint256[3] memory digg_emissions_faucet = [native_digg_fragments, native_uniDiggWbtc_fragments, native_sushiDiggWbtc_fragments];

        /*
            Transfer appropriate DIGG fragments to the faucet
            This value is HALF the stated emissions (half goes to geyser, except in the case of native DIGG)
            Renounce the ability to set rewards for safety
        */
        for (uint256 i = 0; i < faucets.length; i++) {
            IDiggRewardsFaucet rewards = IDiggRewardsFaucet(faucets[i]);

            // Native DIGG has 100% emissions through Faucet, LP has 50% emissions
            uint256 fragments = digg_emissions_faucet[i];
            if (i != 0) {
                fragments = digg_emissions_faucet[i] / 2;
            }
            require(IDigg(digg).transfer(address(rewards), fragments), "faucet transfer");
            rewards.notifyRewardAmount(now, duration, fragments);
            IAccessControl(address(rewards)).renounceRole(DEFAULT_ADMIN_ROLE, address(this));
        }

        // ===== Tree Initial DIGG Supply - 2 days of emissions =====
        require(IDigg(digg).transfer(badgerTree, initial_tree_digg_supply), "badgerTree");

        // ===== Lock Initial Liquidity =====
        IDigg(digg).approve(uniRouter, initial_liquidity_digg);
        IDigg(wbtc).approve(uniRouter, initial_liquidity_wbtc);

        IUniswapRouterV2(uniRouter).addLiquidity(
            digg,
            wbtc,
            initial_liquidity_digg,
            initial_liquidity_wbtc,
            initial_liquidity_digg,
            initial_liquidity_wbtc,
            rewardsEscrow,
            now
        );

        IDigg(digg).approve(sushiRouter, initial_liquidity_digg);
        IDigg(wbtc).approve(sushiRouter, initial_liquidity_wbtc);

        IUniswapRouterV2(sushiRouter).addLiquidity(
            digg,
            wbtc,
            initial_liquidity_digg,
            initial_liquidity_wbtc,
            initial_liquidity_digg,
            initial_liquidity_wbtc,
            rewardsEscrow,
            now
        );

        // ===== Initial DIGG Distribution =====

        // dao_treasury_pct = 40%
        require(IDigg(digg).transfer(daoDiggTimelock, DAO_TREASURY_SUPPLY), "transfer DAO_TREASURY_SUPPLY");

        // team_vesting_pct = 5%
        require(IDigg(digg).transfer(teamVesting, TEAM_VESTING_SUPPLY), "transfer TEAM_VESTING_SUPPLY");

        uint256 remainingBalance = IDigg(digg).balanceOf(address(this));

        // liquidity_mining_pct = 40% - already distributed
        require(LIQUIDITY_MINING_SUPPLY > remainingBalance, "Excess DIGG remaining");
        require(IDigg(digg).transfer(rewardsEscrow, remainingBalance), "transfer LIQUIDITY_MINING_SUPPLY");

        require(IDigg(digg).balanceOf(rewardsEscrow) == remainingBalance, "LIQUIDITY_MINING_SUPPLY");
        require(IDigg(digg).balanceOf(daoDiggTimelock) == DAO_TREASURY_SUPPLY, "DAO_TREASURY_SUPPLY");
        require(IDigg(digg).balanceOf(teamVesting) == TEAM_VESTING_SUPPLY, "TEAM_VESTING_SUPPLY");

        // ===== Open Airdrop & Transfer to Multisig =====
        IDiggDistributor(airdrop).openAirdrop();
        IOwnable(airdrop).transferOwnership(devMultisig);

        require(IDiggDistributor(airdrop).isOpen() == true, "airdrop open");

        seeded = true;
    }
}