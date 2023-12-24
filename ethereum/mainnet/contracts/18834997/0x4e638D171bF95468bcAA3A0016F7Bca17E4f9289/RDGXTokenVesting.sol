// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.23;

// This is developed with OpenZeppelin contracts v4.9.3.
import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./SafeCastUpgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";

import "./IRDGXTokenSale.sol";

/**
 * @title Radiologex (RDGX) token vesting.
 *
 * @notice This contract is the vesting of R-DEE protocol. It is responsible for distribution of RDGX tokens among
 * the four groups of users:
 *
 * 1. Purchasers of the RDGX private sale.
 * 2. Purchasers of the RDGX public sale.
 * 3. Team members including founding members, core team, etc. Their list and total allocations are manually set
 *    using `setMemberAllocations()` by the administrator.
 * 4. STO group. Their list and total allocations are manually set using `setSTOAllocations()` by the administrator.
 *
 * For the groups 1 and 2, see the contract `RDGXTokenSale` for details.
 *
 * The total supply of the RDGX token (`rdgxToken`) is `1E9` tokens (`1_000_000_000_000000000000000000`).
 *
 * RDGX tokens should be transferred to this contract prior to vesting by the RDGX owner.
 *
 * Assumed flow:
 *
 * 1. The private sale ends, the public sale ends. See `RDGXTokenSale` for details.
 * 2. The administrator, who has the role `DEFAULT_ADMIN_ROLE`, sets total allocations for the team members using
 *    `setMemberAllocations()`.
 * 3. The RDGX owner, to whose address the RDGX total supply is pre-minted, transfers RDGX tokens to this contract
 *    in the amount returned by `calcTotalCommonAllocation()`.
 *
 * The following vesting parameters are assumed:
 *
 * - The total allocation is:
 *   - less than or equal to `7%` (`70_000_000`) of the RDGX total supply for the group 1;
 *   - less than or equal to `3%` (`30_000_000`) for the group 2;
 *   - equal to `15%` (`150_000_000`) for the group 3;
 *   - equal to `...%` (`...`) for the group 4.
 *
 *   For the groups 1 and 2 less, in case not everything was purchased at the sale (`RDGXTokenSale`).
 *
 * - The vesting duration and release is:
 *   - a 1-second linear vesting (the instant release) for the group 1;
 *   - a 1-second linear vesting (the instant release) for the group 2;
 *   - a 3-year specified vesting for the group 3:
 *     - `10%` can be released from the end of the 1st year;
 *     - the next `20%` from the end of the 2nd;
 *     - the remaining `70%` from the end of the 3rd (the end of the team members' vesting);
 *   - a 1-second linear vesting (the instant release) for the group 4.
 *
 * @dev The vesting formula is a linear vesting curve or specified release timestamps. For details, see the functions
 * `calcVestedAmountFor()` and `calcSpecifiedVestedAmountFor()`, respectively.
 */
contract RDGXTokenVesting is AccessControlUpgradeable, PausableUpgradeable {
    // _______________ Libraries _______________

    /*
     * Adding the methods from the OpenZeppelin's library which wraps around ERC20 operations that
     * throw on failure to implement their safety.
     */
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /*
     * Adding the methods from the OpenZeppelin's library that wraps number casting operators with
     * added overflow checks.
     */
    using SafeCastUpgradeable for uint256;

    // _______________ Structs _______________

    /**
     * @notice The design of a vesting period:
     * 1. From `cliffStart` to `start`, there is an inactivity period during which no token transfers occur.
     *    All relevant vesting parameters are defined prior to the start of this period.
     * 2. From `start` to `start + duration + 1`, there is a vesting period during or after which accounts, that are
     *    to be vested, can release tokens using the function `release()` or `releaseFor()`.
     */
    struct VestingPeriod {
        uint64 cliffStart;
        uint64 start;
        uint64 duration;
    }

    /**
     * @notice The design of an object used for vestings with specified timestamps of token releases instead of
     * a linear vesting formula. It consists of:
     * - A list of timestamps, starting from which a user can release a part of allocation.
     * - A list of percentages using which allocation parts, that can be released, are determined.
     *
     * See `specifiedVestings` for more details.
     *
     * @dev This is used by vestings instead of the linear formula.
     * In this contract it is only used by the vesting for the team members.
     *
     * Timestamp's array index corresponds to percentage's index.
     */
    struct SpecifiedVesting {
        uint64[] timestamps;
        uint256[] percentages;
    }

    // _______________ Constants _______________

    /// @notice The role of a pauser, who is responsible for pausing and unpausing all token transfers.
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice The decimals of `rdgxToken`.
    uint256 public constant RDGX_TOKEN_DECIMALS = 1E18;

    /// @notice The ID of the vesting for purchasers of the RDGX private sale.
    uint256 public constant PRIVATE_VESTING_ID = 0;

    /// @notice The ID of the vesting for purchasers of the RDGX public sale.
    uint256 public constant PUBLIC_VESTING_ID = 1;

    /// @notice The ID of the vesting for the team members.
    uint256 public constant MEMBER_VESTING_ID = 2;

    /// @notice The ID of the vesting for the STO group.
    uint256 public constant STO_VESTING_ID = 3;

    /**
     * @notice Representation of 100.00%.
     *
     * @dev It is only used for a vesting which uses `specifiedVestings`.
     */
    uint256 public constant ONE_HUNDRED_PERCENT = 10000;

    // _______________ Storage _______________

    /**
     * @notice The ID of the next vesting.
     *
     * @dev In this implementation, it is only used as the total number of vestings.
     */
    uint256 public nextVestingID;

    /**
     * @notice The address of the RDGX token sale.
     *
     * @dev It is used to determine total allocations of RDGX purchasers using `addPrivatePurchase()` and
     * `addPublicPurchase()`, as well as to ensure that the vestings for RDGX purchasers start after the sale ends
     * (`rdgxTokenSale.getSalePeriod()`) in `beforeVestingPeriodSet()`.
     */
    address public rdgxTokenSale;

    /// @notice An account => Vesting's ID => Account's total allocation (to vest and be released).
    mapping(address => mapping(uint256 => uint256)) public totalAllocations;

    /**
     * @notice It is used only for:
     * 1. The function `setMemberAllocations()` of the `MEMBER_VESTING_ID` vesting.
     * 2. The function `setSTOAllocations()` of the `STO_VESTING_ID` vesting.
     *
     * Vesting's ID => Accounts.
     */
    mapping(uint256 => address[]) private accounts;

    /// @notice Vesting's ID => The total allocation for all accounts.
    mapping(uint256 => uint256) public commonAllocations;

    /// @notice Vesting's ID => Vesting's period.
    mapping(uint256 => VestingPeriod) public vestingPeriods;

    /**
     * @notice If this object is specified for a vesting, the vesting uses releases from specific timestamps instead of
     * the linear formula.
     *
     * Vesting's ID => The specified vesting release.
     *
     * @dev In this contract it is only used by the vesting for team members.
     */
    mapping(uint256 => SpecifiedVesting) private specifiedVestings;

    /// @notice The address of the RDGX token.
    IERC20Upgradeable public rdgxToken;

    /// @notice An account => Vesting's ID => An amount of released RDGX tokens.
    mapping(address => mapping(uint256 => uint256)) public releasedAmount;

    /// @notice Vesting's ID => The common released amount for all accounts.
    mapping(uint256 => uint256) public commonReleasedAmount;

    /// @notice An account => Vesting's ID => Are RDGX tokens totally released?
    mapping(address => mapping(uint256 => bool)) private areTotallyReleased;

    // _______________ Errors _______________

    error AdminEqZeroAddr();

    error RDGXTokenSaleEqZeroAddr();

    error RDGXTokenEqZeroAddr();

    error OnlyEighteenDecimals();

    error OnlyBeforeCliffStart(uint256 _current, uint256 _cliffStart);

    error IncorrectVestingPeriod(uint256 _current, VestingPeriod _vestingPeriod);

    error OnlyAfterSaleEnd(uint256 _cliffStart, uint256 _saleEnd);

    error LenMismatchBetwTimestampsNPercentages(uint256 _timestampArrLen, uint256 _percentageArrLen);

    error OnlyWithinVestingPeriod(uint64 _timestamp, VestingPeriod _vestingPeriod);

    error AscendingOrderRequired(uint64 _timestamp, uint64 _nextTimestamp);

    error SumLTOneHundredPercent(uint256 _summary, uint256 _oneHundredPercent);

    error OnlyRDGXTokenSale();

    error LenMismatchBetwAccountsNAmounts(uint256 _accountArrLen, uint256 _amountArrLen);

    error ZeroArrayLength();

    error NoReleasableRDGXFor(address _addr);

    error OnlyAfterReleaseStart(uint256 _current, uint256 _start);

    error UnknownVesting();

    // _______________ Events _______________

    event RDGXTokenSaleSet(address indexed _rdgxTokenSale);

    event RDGXTokenSet(address indexed _rdgxToken);

    event VestingPeriodSet(uint256 indexed _vestingID, VestingPeriod _vestingPeriod);

    event SpecifiedVestingSet(uint256 indexed _vestingID, SpecifiedVesting _specifiedVesting);

    /**
     * @notice Emitted when the total allocation in the amount of `_amount` is set for `_account` for
     * the `_vestingID` vesting.
     */
    event TotalAllocationSet(uint256 indexed _vestingID, address indexed _account, uint256 _amount);

    /**
     * @notice Emitted when the RDGX token in the amount of `_amount` is released for `_account` for
     * the `_vestingID` vesting.
     */
    event Released(address indexed _account, uint256 indexed _vestingID, uint256 _amount);

    // _______________ Modifiers _______________

    /// @notice Modifier that checks that a caller is the RDGX token sale, otherwise reverts.
    modifier onlyRDGXTokenSale() {
        if (_msgSender() != rdgxTokenSale) revert OnlyRDGXTokenSale();
        _;
    }

    // _______________ Initializer _______________

    /**
     * @notice Initializes this contract by:
     * - Setting the address of the RDGX token sale to `_rdgxTokenSale`.
     * - Setting the address of the RDGX token to `_rdgxToken`.
     * - Setting periods for all the vestings: `PRIVATE_VESTING_ID`, `PUBLIC_VESTING_ID` and `MEMBER_VESTING_ID`.
     * - Setting the specified vesting instead of the linear formula for the `MEMBER_VESTING_ID` vesting.
     * - Setting the unpaused state.
     * - Granting the role `DEFAULT_ADMIN_ROLE` to `_administrator`.
     *
     * Warning. The total allocations for the team members should be set using `setMemberAllocations()`
     * after initialization. The RDGX tokens should be transferred to this contract prior to vesting. See
     * the description of this contract for details.
     */
    // prettier-ignore
    function initialize(
        address _administrator,
        address _rdgxTokenSale,
        address _rdgxToken,
        uint64 _privateReleaseStart,
        uint64 _publicReleaseStart,
        uint64 _memberVestingStart,
        SpecifiedVesting calldata _memberSpecifiedVesting,
        uint64 _stoReleaseStart
    ) external initializer {
        if (_administrator == address(0)) revert AdminEqZeroAddr();

        validateNSetRDGXTokenSale(_rdgxTokenSale);
        validateNSetRDGXToken(_rdgxToken);

        // Validating and setting the initial vestings' periods.
        validateNSetVestingPeriod(PRIVATE_VESTING_ID, VestingPeriod(_privateReleaseStart, _privateReleaseStart, 1));
        validateNSetVestingPeriod(PUBLIC_VESTING_ID, VestingPeriod(_publicReleaseStart, _publicReleaseStart, 1));
        validateNSetVestingPeriod(
            MEMBER_VESTING_ID,
            VestingPeriod(
                _memberVestingStart,
                _memberVestingStart,
                _memberSpecifiedVesting.timestamps[_memberSpecifiedVesting.timestamps.length - 1] -
                    _memberVestingStart - 1
            )
        );
        validateNSetSpecifiedVesting(MEMBER_VESTING_ID, _memberSpecifiedVesting);
        validateNSetVestingPeriod(STO_VESTING_ID, VestingPeriod(_stoReleaseStart, _stoReleaseStart, 1));
        nextVestingID = 4;

        __Pausable_init_unchained();

        _grantRole(DEFAULT_ADMIN_ROLE, _administrator);
    }

    // _______________ External functions _______________

    /**
     * @notice Releases the RDGX tokens that have already vested in the caller for all the vestings.
     *
     * Emits `Released` events.
     */
    // prettier-ignore
    function release() external whenNotPaused {
        uint256 num = nextVestingID;
        address account = _msgSender();
        mapping(uint256 => bool) storage refAreTotallyReleased = areTotallyReleased[account];
        mapping(uint256 => uint256) storage refReleasedAmount = releasedAmount[account];
        uint256 amount = 0;
        uint256 sum = 0;
        mapping(uint256 => uint256) storage refTotalAllocations = totalAllocations[account];
        for (uint256 vestingID = 0; vestingID < num; ++vestingID)
            if (!refAreTotallyReleased[vestingID]) {
                amount = calcReleasable(vestingID, account);
                if (amount != 0) {
                    addReleased(
                        refReleasedAmount,
                        vestingID,
                        amount,
                        refTotalAllocations,
                        refAreTotallyReleased,
                        account
                    );

                    sum += amount;
                }
            }

        if (sum == 0) revert NoReleasableRDGXFor(account);

        rdgxToken.safeTransfer(account, sum);
    }

    /**
     * @notice Releases the RDGX tokens that have already vested in `_account` for the `_vestingID` vesting.
     *
     * Emits a `Released` event.
     */
    // prettier-ignore
    function releaseFor(address _account, uint256 _vestingID) external whenNotPaused {
        uint256 amount = calcReleasable(_vestingID, _account);
        if (amount == 0)
            if (block.timestamp < vestingPeriods[_vestingID].start)
                revert OnlyAfterReleaseStart(block.timestamp, vestingPeriods[_vestingID].start);
            else
                revert NoReleasableRDGXFor(_account);

        mapping(uint256 => uint256) storage refReleasedAmount = releasedAmount[_account];
        mapping(uint256 => uint256) storage refTotalAllocations = totalAllocations[_account];
        mapping(uint256 => bool) storage refAreTotallyReleased = areTotallyReleased[_account];
        addReleased(
            refReleasedAmount,
            _vestingID,
            amount,
            refTotalAllocations,
            refAreTotallyReleased,
            _account
        );
        rdgxToken.safeTransfer(_account, amount);
    }

    // ____ Writing purchases for the private and public sales ____

    /**
     * @notice Sets the address of the RDGX token sale which is used in this contract to write total allocations of
     * RDGX purchasers for the vestings `PRIVATE_VESTING_ID` and `PUBLIC_VESTING_ID` using `addPrivatePurchase()` and
     * `addPublicPurchase()`.
     *
     * Emits an `RDGXTokenSaleSet` event.
     */
    function setRDGXTokenSale(address _rdgxTokenSale) external onlyRole(DEFAULT_ADMIN_ROLE) {
        validateNSetRDGXTokenSale(_rdgxTokenSale);
    }

    /**
     * @notice Adds `_rdgxAmount` to the total allocation of `_purchaser` for the vesting `PRIVATE_VESTING_ID`.
     *
     * Emits a `TotalAllocationSet` event.
     *
     * @dev This function is called when purchasing the RDGX token in the amount of `_rdgxAmount` by `_purchaser` on
     * the private sale.
     */
    function addPrivatePurchase(address _purchaser, uint256 _rdgxAmount) external onlyRDGXTokenSale {
        addTotalAllocation(PRIVATE_VESTING_ID, _purchaser, _rdgxAmount);
    }

    /**
     * @notice Adds `_rdgxAmount` to the total allocation of `_purchaser` for the vesting `PUBLIC_VESTING_ID`.
     *
     * Emits a `TotalAllocationSet` event.
     *
     * @dev This function is called when purchasing the RDGX token in the amount of `_rdgxAmount` by `_purchaser` on
     * the public sale.
     */
    function addPublicPurchase(address _purchaser, uint256 _rdgxAmount) external onlyRDGXTokenSale {
        addTotalAllocation(PUBLIC_VESTING_ID, _purchaser, _rdgxAmount);
    }

    // ____ Administrative functionality ____

    /**
     * @notice Sets total allocations (`_amounts`) of all the team members (`_teamMembers`) for the `MEMBER_VESTING_ID`
     * vesting.
     *
     * Emits a `TotalAllocationSet` event for each team member.
     *
     * Warning. This function should be executed for the operation of the `MEMBER_VESTING_ID` vesting.
     *
     * Requirements:
     * - The caller should have the role `DEFAULT_ADMIN_ROLE`.
     * - The lengths of the arrays `_teamMembers` and `_amounts` should be equal and not be zero.
     * - If this function has already been executed, the current timestamp should be less than the start of
     *   the cliff period of the `MEMBER_VESTING_ID` vesting.
     *
     * @param _teamMembers An array of all the team members for which total allocations are to be set.
     * @param _amounts Total allocations are to be set for the team members.
     */
    // prettier-ignore
    function setMemberAllocations(
        address[] calldata _teamMembers,
        uint256[] calldata _amounts
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setAllocations(MEMBER_VESTING_ID, _teamMembers, _amounts);
    }

    // prettier-ignore
    function setSTOAllocations(
        address[] calldata _stoGroup,
        uint256[] calldata _amounts
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        setAllocations(STO_VESTING_ID, _stoGroup, _amounts);
    }

    /**
     * @notice Pauses all token transfers.
     *
     * Emits a `Paused` event.
     *
     * Requirements:
     * - The caller should have the role `PAUSER_ROLE`.
     * - The contract should not be paused.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses all token transfers.
     *
     * Emits an `Unpaused` event.
     *
     * Requirements:
     * - The caller should have the role `PAUSER_ROLE`.
     * - The contract should be paused.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @notice Sets the address of the RDGX token contract (`rdgxToken`) which is resposible for functionality of
     * RDGX tokens and used in this contract to transfer released tokens.
     *
     * Emits an `RDGXTokenSet` event.
     *
     * Requirements:
     *  - The caller should have the default administrator role (`DEFAULT_ADMIN_ROLE`).
     *  - `_rdgxToken` should not be equal to the zero address.
     *  - `_rdgxToken` should have `RDGX_TOKEN_DECIMALS` decimals.
     *
     * @param _rdgxToken The address of the RDGX token contract.
     */
    function setRDGXToken(address _rdgxToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        validateNSetRDGXToken(_rdgxToken);
    }

    /**
     * @notice Sets the period of the `_vestingID` vesting to `_vestingPeriod`.
     *
     * Emits a `VestingPeriodSet` event.
     */
    // prettier-ignore
    function setVestingPeriod(
        uint256 _vestingID,
        VestingPeriod memory _vestingPeriod
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_vestingID >= nextVestingID) revert UnknownVesting();
        if (block.timestamp >= vestingPeriods[_vestingID].cliffStart)
            revert OnlyBeforeCliffStart(block.timestamp, vestingPeriods[_vestingID].cliffStart);

        validateNSetVestingPeriod(_vestingID, _vestingPeriod);
    }

    /**
     * @notice Sets the specific timestamps, from which specific parts of RDGX tokens can be released, for
     * the `_vestingID` vesting.
     *
     * It is used for a vesting instead of the linear formula if set.
     *
     * Emits a `SpecifiedVestingSet` event.
     *
     * For example:
     * 1. If `vestingPeriods[_vestingID].start` is `1699436428` and
     *    `_specifiedVesting == { timestamps: [1699436428, 1731058853], percentages: [2500, 7500] }`, then
     *    each account, which is vested during the `_vestingID` vesting, can release `25%` of RDGX tokens from the
     *    start of the `_vestingID` vesting and the remaining `75%` of RDGX tokens from the end of
     *    the `_vestingID` vesting.
     * 2. If `vestingPeriods[_vestingID].start` is `1699000000` and `_specifiedVesting == {
     *    timestamps: [1699436428, 1700436428, 1731058853], percentages: [1250, 3750, 5000] }`, then
     *    each account, which is vested during the `_vestingID` vesting, can release `12.5%` from `1699436428`,
     *    the next `37.5%` from `1700436428` and the remaining `50%` from the end of the `_vestingID` vesting.
     *
     * A `_vestingID` vesting can be switched to the linear formula again with `_specifiedVesting` equal to
     * `{ timestamps: [], percentages: [] }`.
     */
    // prettier-ignore
    function setSpecifiedVesting(
        uint256 _vestingID,
        SpecifiedVesting calldata _specifiedVesting
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_vestingID >= nextVestingID) revert UnknownVesting();
        if (block.timestamp >= vestingPeriods[_vestingID].cliffStart)
            revert OnlyBeforeCliffStart(block.timestamp, vestingPeriods[_vestingID].cliffStart);

        validateNSetSpecifiedVesting(_vestingID, _specifiedVesting);
    }

    // ____ Extra getters ____

    /**
     * @notice Returns the total RDGX amount to vest for all the accounts during all the vestings.
     * That is, the return amount is equal to the summary of total allocations for all the accounts for
     * all the vestings.
     */
    // prettier-ignore
    function calcTotalCommonAllocation() external view returns (uint256 sum) {
        uint256 num = nextVestingID;
        for (uint256 vestingID = 0; vestingID < num; ++vestingID)
            sum += commonAllocations[vestingID];
        return sum;
    }

    /**
     * @notice Returns the total RDGX amount that is released for all the accounts during all the vestings.
     * That is, the return amount is equal to the summary of all releases for all the accounts for all the vestings.
     */
    // prettier-ignore
    function calcTotalCommonReleasedAmount() external view returns (uint256 sum) {
        uint256 num = nextVestingID;
        for (uint256 vestingID = 0; vestingID < num; ++vestingID)
            sum += commonReleasedAmount[vestingID];
        return sum;
    }

    /**
     * @notice Calculates the timestamp of the end of the vesting `_vestingID`.
     *
     * @param _vestingID The vesting identifier.
     */
    function calcVestingEnd(uint256 _vestingID) external view returns (uint64) {
        VestingPeriod storage refVestingPeriod = vestingPeriods[_vestingID];
        return refVestingPeriod.start + refVestingPeriod.duration + 1;
    }

    /**
     * @notice Returns the specific timestamps, from which specific parts of RDGX tokens can be released, for
     * the `_vestingID` vesting.
     *
     * If this object is empty for the `_vestingID` vesting, then the vesting uses the linear formula.
     *
     * @param _vestingID The vesting identifier.
     */
    function getSpecifiedVesting(uint256 _vestingID) external view returns (SpecifiedVesting memory) {
        return specifiedVestings[_vestingID];
    }

    /// @notice See `accounts` for details.
    function getVestingAccounts(uint256 _vestingID) external view returns (address[] memory) {
        return accounts[_vestingID];
    }

    // _______________ Public functions _______________

    /**
     * @notice Calculates the amount of releasable RDGX tokens for `_account` for the vesting `_vestingID`.
     *
     * @param _vestingID The vesting identifier.
     * @param _account The account for which to calculate the amount of releasable RDGX tokens.
     */
    function calcReleasable(uint256 _vestingID, address _account) public view returns (uint256) {
        return calcVestedAmount(_vestingID, _account, uint64(block.timestamp)) - releasedAmount[_account][_vestingID];
    }

    /**
     * @notice Calculates the amount of RDGX tokens vested at the time of `_timestamp` for `_account` for the vesting
     * `_vestingID`.
     *
     * @param _vestingID The vesting identifier.
     * @param _account The account for which to calculate the amount of vested RDGX tokens.
     * @param _timestamp The timestamp for which you want to calculate the amount of vested RDGX tokens.
     */
    // prettier-ignore
    function calcVestedAmount(uint256 _vestingID, address _account, uint64 _timestamp) public view returns (uint256) {
        SpecifiedVesting storage refSpecifiedVesting = specifiedVestings[_vestingID];
        VestingPeriod storage refVestingPeriod = vestingPeriods[_vestingID];
        // It is a linear vesting.
        if (refSpecifiedVesting.timestamps.length == 0)
            return calcVestedAmountFor(
                _timestamp,
                refVestingPeriod.start,
                refVestingPeriod.duration,
                totalAllocations[_account][_vestingID]
            );
        // Otherwise, it is a specified vesting. See `specifiedVestings` for details.
        return calcSpecifiedVestedAmountFor(
            _timestamp,
            refVestingPeriod.start,
            refVestingPeriod.duration,
            totalAllocations[_account][_vestingID],
            refSpecifiedVesting
        );
    }

    // _______________ Private functions _______________

    function validateNSetRDGXTokenSale(address _rdgxTokenSale) private {
        if (_rdgxTokenSale == address(0)) revert RDGXTokenSaleEqZeroAddr();
        rdgxTokenSale = _rdgxTokenSale;
        emit RDGXTokenSaleSet(_rdgxTokenSale);
    }

    // prettier-ignore
    function validateNSetRDGXToken(address _rdgxToken) private {
        if (_rdgxToken == address(0)) revert RDGXTokenEqZeroAddr();
        if (10 ** IERC20MetadataUpgradeable(_rdgxToken).decimals() != RDGX_TOKEN_DECIMALS)
            revert OnlyEighteenDecimals();

        rdgxToken = IERC20Upgradeable(_rdgxToken);
        emit RDGXTokenSet(_rdgxToken);
    }

    // prettier-ignore
    function validateNSetVestingPeriod(uint256 _vestingID, VestingPeriod memory _vestingPeriod) private {
        if (
            _vestingPeriod.cliffStart < block.timestamp ||
                _vestingPeriod.cliffStart > _vestingPeriod.start ||
                _vestingPeriod.duration == 0
        ) revert IncorrectVestingPeriod(block.timestamp, _vestingPeriod);

        beforeVestingPeriodSet(_vestingID, _vestingPeriod);

        vestingPeriods[_vestingID] = _vestingPeriod;
        emit VestingPeriodSet(_vestingID, _vestingPeriod);
    }

    // prettier-ignore
    function validateNSetSpecifiedVesting(uint256 _vestingID, SpecifiedVesting calldata _specifiedVesting) private {
        uint256 sz = _specifiedVesting.percentages.length;
        if (sz != _specifiedVesting.timestamps.length)
            revert LenMismatchBetwTimestampsNPercentages(_specifiedVesting.timestamps.length, sz);

        if (sz != 0) {
            VestingPeriod storage vestingPeriod = vestingPeriods[_vestingID];
            uint64 vestingStart = vestingPeriod.start;
            if (_specifiedVesting.timestamps[0] < vestingStart)
                revert OnlyWithinVestingPeriod(_specifiedVesting.timestamps[0], vestingPeriod);
            if (_specifiedVesting.timestamps[sz - 1] != vestingStart + vestingPeriod.duration + 1)
                revert OnlyWithinVestingPeriod(_specifiedVesting.timestamps[sz - 1], vestingPeriod);

            uint256 sum = _specifiedVesting.percentages[0];
            unchecked {
                for (uint256 i = 1; i < sz; ++i) {
                    sum += _specifiedVesting.percentages[i];

                    if (_specifiedVesting.timestamps[i - 1] >= _specifiedVesting.timestamps[i])
                        revert AscendingOrderRequired(
                            _specifiedVesting.timestamps[i - 1],
                            _specifiedVesting.timestamps[i]
                        );
                }
            }
            if (sum != ONE_HUNDRED_PERCENT) revert SumLTOneHundredPercent(sum, ONE_HUNDRED_PERCENT);
        }

        specifiedVestings[_vestingID] = _specifiedVesting;
        emit SpecifiedVestingSet(_vestingID, _specifiedVesting);
    }

    // prettier-ignore
    function addTotalAllocation(uint256 _vestingID, address _account, uint256 _rdgxAmount) private {
        commonAllocations[_vestingID] += _rdgxAmount;

        mapping(uint256 => bool) storage refAreTotallyReleased = areTotallyReleased[_account];
        if (refAreTotallyReleased[_vestingID])
            delete refAreTotallyReleased[_vestingID];

        mapping(uint256 => uint256) storage refTotalAllocation = totalAllocations[_account];
        // Cannot be overflowed, as `commonAllocations[_vestingID]`, which is `uint256`, overflows before.
        uint256 newTotalAllocation;
        unchecked {
            newTotalAllocation = refTotalAllocation[_vestingID] + _rdgxAmount;
        }
        refTotalAllocation[_vestingID] = newTotalAllocation;
        emit TotalAllocationSet(_vestingID, _account, newTotalAllocation);
    }

    // It is only used for the vestings `MEMBER_VESTING_ID` and `STO_VESTING_ID`.
    // prettier-ignore
    function setAllocations(
        uint256 _vestingID,
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) private {
        uint256 len = _accounts.length;
        if (len != _amounts.length)
            revert LenMismatchBetwAccountsNAmounts(len, _amounts.length);
        if (len == 0) revert ZeroArrayLength();

        if (
            block.timestamp >= vestingPeriods[_vestingID].cliffStart &&
                commonAllocations[_vestingID] != 0
        ) revert OnlyBeforeCliffStart(block.timestamp, vestingPeriods[_vestingID].cliffStart);

        // Removing the previous allocations.
        address[] storage refAccounts = accounts[_vestingID];
        uint256 sz = refAccounts.length;
        uint256 i = 0;
        if (sz > 0)
            for (; i < sz; ++i)
                delete totalAllocations[refAccounts[i]][_vestingID];

        // Replacing accounts.
        accounts[_vestingID] = _accounts;

        uint256 sum = 0;
        for (i = 0; i < len; ++i) {
            totalAllocations[_accounts[i]][_vestingID] = _amounts[i];
            emit TotalAllocationSet(_vestingID, _accounts[i], _amounts[i]);
            sum += _amounts[i];
        }
        commonAllocations[_vestingID] = sum;
    }

    // prettier-ignore
    function addReleased(
        mapping(uint256 => uint256) storage refReleasedAmount,
        uint256 _vestingID,
        uint256 _amount,
        mapping(uint256 => uint256) storage refTotalAllocations,
        mapping(uint256 => bool) storage refAreTotallyReleased,
        address _account
    ) private {
        uint256 newReleasedAmount;
        // Cannot be overflowed, as the common allocation is `uint256`.
        unchecked {
            newReleasedAmount = refReleasedAmount[_vestingID] + _amount;
            refReleasedAmount[_vestingID] = newReleasedAmount;
            commonReleasedAmount[_vestingID] += _amount;
        }
        emit Released(_account, _vestingID, _amount);

        if (refTotalAllocations[_vestingID] <= newReleasedAmount)
            refAreTotallyReleased[_vestingID] = true;
    }

    /*
     * Hook used to add additional requirements for specific vestings when setting their periods.
     *
     * In this contract this is only used for the vestings `PRIVATE_VESTING_ID` and `PUBLIC_VESTING_ID`.
     */
    // prettier-ignore
    function beforeVestingPeriodSet(uint256 _vestingID, VestingPeriod memory _vestingPeriod) private view {
        if (_vestingID < MEMBER_VESTING_ID) {
            ( , uint256 saleEnd) = IRDGXTokenSale(rdgxTokenSale).getSalePeriod(
                _vestingID == PRIVATE_VESTING_ID ? true : false
            );
            if (_vestingPeriod.cliffStart < saleEnd.toUint64())
                revert OnlyAfterSaleEnd(_vestingPeriod.cliffStart, saleEnd);
        }
    }

    /**
     * @notice Calculates the amount of tokens that has already vested for vestings that use `specifiedVestings`
     * instead of the linear formula (`calcVestedAmountFor()`).
     */
    // prettier-ignore
    function calcSpecifiedVestedAmountFor(
        uint64 _timestamp,
        uint64 _start,
        uint64 _duration,
        uint256 _totalAllocation,
        SpecifiedVesting storage _refSpecifiedVesting
    ) private view returns (uint256) {
        if (_timestamp < _start)
            return 0;
        if (_timestamp > _start + _duration)
            return _totalAllocation;

        uint256 percentage = 0;
        unchecked {
            uint256 num = _refSpecifiedVesting.timestamps.length - 1;
            for (uint256 i = 0; i < num; ++i)
                if (_timestamp >= _refSpecifiedVesting.timestamps[i])
                    percentage += _refSpecifiedVesting.percentages[i];
        }
        return _totalAllocation * percentage / ONE_HUNDRED_PERCENT;
    }

    /**
     * @notice Calculates the amount of tokens that has already vested.
     *
     * @param _timestamp The timestamp for which an amount of vested tokens is to be calculated.
     * @param _start The timestamp of the start of a vesting.
     * @param _duration Total duration of a vesting.
     * @param _totalAllocation Total amount of tokens to vest.
     *
     * @dev The vesting formula is a linear vesting curve. This returns the amount vested, as a function of time,
     * for an asset given its total historical allocation.
     *
     * Adopted from the OpenZeppelin's `VestingWallet` contract (v4.9.3).
     */
    // prettier-ignore
    function calcVestedAmountFor(
        uint64 _timestamp,
        uint64 _start,
        uint64 _duration,
        uint256 _totalAllocation
    ) private pure returns (uint256) {
        if (_timestamp < _start)
            return 0;
        if (_timestamp > _start + _duration)
            return _totalAllocation;
        return _totalAllocation * (_timestamp - _start) / _duration;
    }
}
