// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

/**
 * @title A contract to hold escrowed tokens and free them at given schedules.
 * @notice contract handles any given token
 * @notice Escrow period for each token may be different
 */
contract RewardEscrow is Initializable, OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== State Variables ========== */

    /* True if the address can append vesting entries */
    /* Reward contracts for this escrow contract are clr pools */
    mapping(address => bool) public isRewardContract;

    /* Lists of (timestamp, quantity) pairs per pool per token per account, sorted in ascending time order.
     * These are the times at which each given quantity of the token vests. */
    /** CLR pool => Token => Account => (vest timestamp, vest amount) */
    mapping(address => mapping(address => mapping(address => uint256[2][])))
        public vestingSchedules;

    /* An account's total escrowed token balance */
    /* token address => account => total escrowed balance. */
    mapping(address => mapping(address => uint256))
        public totalEscrowedAccountBalance;

    /* An account's total vested reward token. */
    /* token address => account => total vested. */
    mapping(address => mapping(address => uint256))
        public totalVestedAccountBalance;

    /* The total remaining escrowed balance, */
    /* for verifying against the actual token balance of this contract. */
    mapping(address => uint256) public totalEscrowedBalance;

    /* CLR pool vesting period */
    /* Each CLR pool may have unlimited number of tokens */
    mapping(address => uint256) public clrPoolVestingPeriod;

    uint256 constant TIME_INDEX = 0;
    uint256 constant QUANTITY_INDEX = 1;

    /* Limit vesting entries to disallow unbounded iteration over vesting schedules.
     * Community vesting won't last longer than 5 years */
    uint256 public constant MAX_VESTING_ENTRIES = 52 * 5;

    /* ========== Management Functions ========== */

    function initialize() external initializer {
        __Ownable_init();
    }

    /**
     * @notice Add a whitelisted rewards contract
     * @notice Reward contracts may append vesting entries for address
     * @notice Reward contracts are clr pools
     */
    function addRewardsContract(address _rewardContract) external onlyOwner {
        if (!isRewardContract[_rewardContract]) {
            isRewardContract[_rewardContract] = true;
            emit RewardContractAdded(_rewardContract);
        }
    }

    /**
     * @notice Remove a whitelisted rewards contract
     */
    function removeRewardsContract(address _rewardContract) external onlyOwner {
        if (isRewardContract[_rewardContract]) {
            isRewardContract[_rewardContract] = false;
            emit RewardContractRemoved(_rewardContract);
        }
    }

    /**
     * @notice Set the vesting period for a given CLR pool
     * @notice Any CLR pool may have unlimited number of reward tokens
     * @notice All reward tokens in pool share the same vesting period
     */
    function setCLRPoolVestingPeriod(address pool, uint256 vestingPeriod)
        external
        onlyOwner
    {
        clrPoolVestingPeriod[pool] = vestingPeriod;
        emit VestingPeriodSet(pool, vestingPeriod);
    }

    /* ========== View Functions ========== */

    /**
     * @notice A simple alias to totalEscrowedAccountBalance: provides ERC20 balance integration.
     */
    function balanceOf(address token, address account)
        public
        view
        returns (uint256)
    {
        return totalEscrowedAccountBalance[token][account];
    }

    /**
     * @notice A simple alias to totalEscrowedBalance: provides ERC20 totalSupply integration.
     */
    function totalSupply(address token) external view returns (uint256) {
        return totalEscrowedBalance[token];
    }

    /**
     * @notice The number of vesting dates in an account's schedule for a given pool.
     */
    function numVestingEntries(
        address pool,
        address token,
        address account
    ) public view returns (uint256) {
        return vestingSchedules[pool][token][account].length;
    }

    /**
     * @notice Get a particular schedule entry for a clr pool and token for an account.
     * @return A pair of uints: (timestamp, token quantity).
     */
    function getVestingScheduleEntry(
        address pool,
        address token,
        address account,
        uint256 index
    ) public view returns (uint256[2] memory) {
        return vestingSchedules[pool][token][account][index];
    }

    /**
     * @notice Get the time at which a given schedule entry will vest for a given pool.
     */
    function getVestingTime(
        address pool,
        address token,
        address account,
        uint256 index
    ) public view returns (uint256) {
        return getVestingScheduleEntry(pool, token, account, index)[TIME_INDEX];
    }

    /**
     * @notice Get the quantity of reward tokens associated with a given schedule entry.
     */
    function getVestingQuantity(
        address pool,
        address token,
        address account,
        uint256 index
    ) public view returns (uint256) {
        return
            getVestingScheduleEntry(pool, token, account, index)[
                QUANTITY_INDEX
            ];
    }

    /**
     * @notice Obtain the index of the next schedule entry that will vest for a given user.
     */
    function getNextVestingIndex(
        address pool,
        address token,
        address account
    ) public view returns (uint256) {
        uint256 len = numVestingEntries(pool, token, account);
        for (uint256 i = 0; i < len; i++) {
            if (getVestingTime(pool, token, account, i) != 0) {
                return i;
            }
        }
        return len;
    }

    /**
     * @notice Obtain the next schedule entry that will vest for a given user.
     * @return A pair of uints: (timestamp, token quantity). */
    function getNextVestingEntry(
        address pool,
        address token,
        address account
    ) public view returns (uint256[2] memory) {
        uint256 index = getNextVestingIndex(pool, token, account);
        if (index == numVestingEntries(pool, token, account)) {
            return [uint256(0), 0];
        }
        return getVestingScheduleEntry(pool, token, account, index);
    }

    /**
     * @notice Obtain the time at which the next schedule entry will vest for a given user.
     */
    function getNextVestingTime(
        address pool,
        address token,
        address account
    ) external view returns (uint256) {
        return getNextVestingEntry(pool, token, account)[TIME_INDEX];
    }

    /**
     * @notice Obtain the quantity which the next schedule entry will vest for a given user.
     */
    function getNextVestingQuantity(
        address pool,
        address token,
        address account
    ) external view returns (uint256) {
        return getNextVestingEntry(pool, token, account)[QUANTITY_INDEX];
    }

    /**
     * @notice return the full vesting schedule entries vest for a given user.
     */
    function checkAccountSchedule(
        address pool,
        address token,
        address account
    ) external view returns (uint256[520] memory) {
        uint256[520] memory _result;
        uint256 schedules = numVestingEntries(pool, token, account);
        for (uint256 i = 0; i < schedules; i++) {
            uint256[2] memory pair = getVestingScheduleEntry(
                pool,
                token,
                account,
                i
            );
            _result[i * 2] = pair[0];
            _result[i * 2 + 1] = pair[1];
        }
        return _result;
    }

    /* ========== Mutative Functions ========== */

    /**
     * @notice Add a new vesting entry at a given time and quantity to an account's schedule.
     * @dev A call to this should accompany a previous successfull call to token.transfer(rewardEscrow, amount),
     * to ensure that when the funds are withdrawn, there is enough balance.
     * Note; although this function could technically be used to produce unbounded
     * arrays, it's only within the limited period of the rewards program (max: 4 years).
     * @param token The address of the reward token.
     * @param account The account to append a new vesting entry to.
     * @param pool The address of the CLR pool for this reward token
     * @param quantity The quantity of reward token that will be escrowed.
     */
    function appendVestingEntry(
        address token,
        address account,
        address pool,
        uint256 quantity
    ) external onlyRewardsContract {
        /* There must be enough balance in the contract to provide for the vesting entry. */
        totalEscrowedBalance[token] = totalEscrowedBalance[token].add(quantity);
        require(
            totalEscrowedBalance[token] <=
                IERC20(token).balanceOf(address(this)),
            "Not enough balance in the contract to provide for the vesting entry"
        );

        /* Disallow arbitrarily long vesting schedules in light of the gas limit. */
        uint256 scheduleLength = vestingSchedules[pool][token][account].length;
        require(
            scheduleLength <= MAX_VESTING_ENTRIES,
            "Vesting schedule is too long"
        );

        /* Escrow the tokens for the given token vesting period after claim. */
        uint256 time = block.timestamp + clrPoolVestingPeriod[pool];

        totalEscrowedAccountBalance[token][
            account
        ] = totalEscrowedAccountBalance[token][account].add(quantity);

        vestingSchedules[pool][token][account].push([time, quantity]);

        emit VestingEntryCreated(
            pool,
            token,
            account,
            block.timestamp,
            quantity
        );
    }

    /**
     * @notice allows an user to withdraw multiple tokens in their schedule that have vested
     * @param pool address of the clr pool associated with these reward tokens
     * @param tokens addresses of the reward tokens to withdraw
     */
    function vestAll(address pool, address[] calldata tokens) external {
        for (uint256 i = 0; i < tokens.length; ++i) {
            vest(pool, tokens[i]);
        }
    }

    /**
     * @notice Allow a user to withdraw any token in their schedule that have vested.
     * @param pool address of the clr pool associated with this reward token
     * @param token address of the reward token to withdraw
     */
    function vest(address pool, address token) public {
        uint256 numEntries = numVestingEntries(pool, token, msg.sender);
        uint256 total;
        for (uint256 i = 0; i < numEntries; i++) {
            uint256 time = getVestingTime(pool, token, msg.sender, i);
            /* The list is sorted; when we reach the first future time, bail out. */
            if (time > block.timestamp) {
                continue;
            }
            uint256 qty = getVestingQuantity(pool, token, msg.sender, i);
            if (qty == 0) {
                continue;
            }

            vestingSchedules[pool][token][msg.sender][i] = [0, 0];
            total = total.add(qty);
        }

        if (total != 0) {
            totalEscrowedBalance[token] = totalEscrowedBalance[token].sub(
                total
            );
            totalEscrowedAccountBalance[token][
                msg.sender
            ] = totalEscrowedAccountBalance[token][msg.sender].sub(total);
            totalVestedAccountBalance[token][
                msg.sender
            ] = totalVestedAccountBalance[token][msg.sender].add(total);
            IERC20(token).safeTransfer(msg.sender, total);
            emit Vested(pool, token, msg.sender, block.timestamp, total);
            emit Transfer(token, msg.sender, address(0), total);
        }
    }

    /* ========== MODIFIERS ========== */

    modifier onlyRewardsContract() {
        require(
            isRewardContract[msg.sender],
            "Only reward contract can perform this action"
        );
        _;
    }

    /* ========== EVENTS ========== */

    event Vested(
        address indexed pool,
        address indexed token,
        address indexed beneficiary,
        uint256 time,
        uint256 value
    );

    event VestingEntryCreated(
        address indexed pool,
        address indexed token,
        address indexed beneficiary,
        uint256 time,
        uint256 value
    );

    event Transfer(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 value
    );

    event RewardContractAdded(address indexed rewardContract);

    event RewardContractRemoved(address indexed rewardContract);

    event VestingPeriodSet(address indexed pool, uint256 vestingPeriod);
}
