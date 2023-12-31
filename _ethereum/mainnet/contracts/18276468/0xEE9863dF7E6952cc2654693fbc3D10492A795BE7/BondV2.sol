// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./EnumerableSet.sol";

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";

import "./IAddressProvider.sol";
import "./IGuardian.sol";
import "./IPriceOracleAggregator.sol";

contract BondV2 is
    ERC1155HolderUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /* ======== STORAGE ======== */

    struct Bond {
        uint256 depositId; // deposit Id
        address principal; // token used to create bond
        uint256 amount; // princial deposited amount
        uint256 payout; // shezmu remaining to be paid
        uint256 guardians; // guardians locked
        uint256 vesting; // Blocks left to vest
        uint256 lastBlockAt; // Last interaction
        uint256 pricePaid; // In DAI, for front end viewing
        address depositor; //deposit address
    }

    struct RewardInfo {
        uint256 debt;
        uint256 pending;
    }

    /// @notice percent multiplier (100%)
    uint256 public constant MULTIPLIER = 10000;

    /// @notice shezmu decimals
    uint256 public constant UNIT = 1e18;

    /// @notice address provider
    IAddressProvider public addressProvider;

    /// @dev tokens used to create bond
    EnumerableSet.AddressSet private principals;

    /// @notice guardian reward fee
    uint256 public guardianRewardFee;

    /// @notice id of deposit
    uint256 public depositId;

    /// @notice mapping depositId => bond info
    mapping(uint256 => Bond) public bondInfo;

    /// @dev mapping depositId => reward info
    mapping(uint256 => RewardInfo) private rewardInfoOf;

    /// @dev mapping depositId => dividendsInfo
    mapping(uint256 => RewardInfo) private dividendsInfoOf;

    /// @dev mapping account => depositId array
    mapping(address => EnumerableSet.UintSet) private ownedDeposits;

    /// @notice stores locking periods of discounts
    uint256[] public lockingPeriods;

    /// @notice mapping locking period => discount
    mapping(uint256 => uint256) public lockingDiscounts;

    /// @notice total deposited value
    uint256 public totalDepositedValue;

    /// @notice total remaining payout for bonding
    uint256 public totalRemainingPayout;

    /// @notice total amount of payout assets sold to the bonders
    uint256 public totalBondedValue;

    /// @notice mapping principal => total bonded amount
    mapping(address => uint256) public totalPrincipals;

    /// @dev reward accTokenPerShare
    uint256 private accTokenPerShare;

    /// @dev USDC dividendsPerShare
    uint256 private dividendsPerShare;

    /* ======== EVENTS ======== */

    event BondCreated(
        uint256 depositId,
        address principal,
        uint256 deposit,
        uint256 indexed payout,
        uint256 indexed expires,
        uint256 indexed priceInUSD
    );
    event BondRedeemed(
        uint256 depositId,
        address indexed recipient,
        uint256 payout,
        uint256 guardians,
        uint256 remaining
    );
    event BondMinted(
        uint256 depositId,
        address indexed recipient,
        uint256 payout,
        uint256 guardians
    );

    /* ======== ERRORS ======== */

    error INVALID_ADDRESS();
    error INVALID_AMOUNT();
    error INVALID_PERIOD();
    error INVALID_PRINCIPAL();
    error LIMIT_SLIPPAGE();
    error TOO_SMALL();
    error INSUFFICIENT_BALANCE();
    error NOT_OWNED_DEPOSIT();
    error NOT_FULLY_VESTED();
    error EXCEED_AMOUNT();

    /* ======== INITIALIZATION ======== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _addressProvider) external initializer {
        if (_addressProvider == address(0)) revert INVALID_ADDRESS();

        // address provider
        addressProvider = IAddressProvider(_addressProvider);

        // guardian reward fee
        guardianRewardFee = MULTIPLIER / 2;

        // deposit index
        depositId = 1;

        // init
        __ERC1155Holder_init();
        __Ownable_init();
        __Pausable_init();
    }

    /* ======== MODIFIER ======== */

    modifier onlyPrincipal(address _principal) {
        if (!principals.contains(_principal)) revert INVALID_PRINCIPAL();
        _;
    }

    modifier update() {
        _receiveGuardianReward();
        _;
    }

    /* ======== POLICY FUNCTIONS ======== */

    /**
     * @notice set discount for locking period
     * @param _lockingPeriod uint
     * @param _discount uint
     */
    function setLockingDiscount(
        uint256 _lockingPeriod,
        uint256 _discount
    ) external onlyOwner {
        if (_lockingPeriod == 0) revert INVALID_PERIOD();
        if (_discount >= MULTIPLIER) revert INVALID_AMOUNT();

        // remove locking period
        if (_discount == 0) {
            uint256 length = lockingPeriods.length;

            for (uint256 i = 0; i < length; i++) {
                if (lockingPeriods[i] == _lockingPeriod) {
                    lockingPeriods[i] = lockingPeriods[length - 1];
                    delete lockingPeriods[length - 1];
                    lockingPeriods.pop();
                }
            }
        }
        // push if new locking period
        else if (lockingDiscounts[_lockingPeriod] == 0) {
            lockingPeriods.push(_lockingPeriod);
        }

        lockingDiscounts[_lockingPeriod] = _discount;
    }

    /**
     * @notice set address provider
     * @param _addressProvider address
     */
    function setAddressProvider(address _addressProvider) external onlyOwner {
        if (_addressProvider == address(0)) revert INVALID_ADDRESS();
        addressProvider = IAddressProvider(_addressProvider);
    }

    /**
     * @notice add principals
     * @param _principals address[]
     */
    function addPrincipals(address[] calldata _principals) external onlyOwner {
        uint256 length = _principals.length;

        for (uint256 i = 0; i < length; i++) {
            address principal = _principals[i];
            if (principal == address(0)) revert INVALID_PRINCIPAL();

            principals.add(principal);
        }
    }

    /**
     * @notice remove principals
     * @param _principals address[]
     */
    function removePrincipals(
        address[] calldata _principals
    ) external onlyOwner {
        uint256 length = _principals.length;

        for (uint256 i = 0; i < length; i++) {
            address principal = _principals[i];
            if (principal == address(0)) revert INVALID_PRINCIPAL();

            principals.remove(principal);
        }
    }

    /**
     * @notice deposit for bond
     * @param _amount uint
     */
    function depositForBond(uint256 _amount) external onlyOwner {
        IERC20(addressProvider.getShezmu()).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        totalDepositedValue += _amount;
    }

    /**
     * @notice recover tokens
     */
    function recoverERC20(IERC20 _token) external onlyOwner {
        uint256 amount = _token.balanceOf(address(this));

        if (address(_token) == addressProvider.getShezmu()) {
            amount = amount - totalRemainingPayout;
            totalDepositedValue -= amount;
        }

        _token.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice pause
     */
    function pause() external onlyOwner whenNotPaused {
        return _pause();
    }

    /**
     * @notice unpause
     */
    function unpause() external onlyOwner whenPaused {
        return _unpause();
    }

    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice deposit bond
     *  @param _principal address
     *  @param _amount uint
     *  @param _maxPrice uint
     *  @param _lockingPeriod uint
     *  @return uint
     */
    function deposit(
        address _principal,
        uint256 _amount,
        uint256 _maxPrice,
        uint256 _lockingPeriod
    ) external onlyPrincipal(_principal) whenNotPaused returns (uint256) {
        if (_amount == 0) revert INVALID_AMOUNT();

        uint256 discount = lockingDiscounts[_lockingPeriod];
        if (discount == 0) revert INVALID_PERIOD();

        uint256 priceInUSD = (bondPrice() * (MULTIPLIER - discount)) /
            MULTIPLIER; // Stored in bond info
        if (priceInUSD > _maxPrice) revert LIMIT_SLIPPAGE();

        uint256 payout = payoutFor(_principal, _amount, discount); // payout to bonder is computed
        if (payout < UNIT / 100) revert TOO_SMALL(); // must be > 0.01 shezmu

        // total remaining payout is increased
        totalRemainingPayout = totalRemainingPayout + payout;

        // total bonded value is increased
        totalBondedValue = totalBondedValue + payout;
        if (totalDepositedValue < totalBondedValue)
            revert INSUFFICIENT_BALANCE();

        // principal is transferred
        IERC20(_principal).safeTransferFrom(
            msg.sender,
            addressProvider.getTreasury(),
            _amount
        );

        totalPrincipals[_principal] = totalPrincipals[_principal] + _amount;

        // depositor info is stored
        bondInfo[depositId] = Bond({
            depositId: depositId,
            principal: _principal,
            amount: _amount,
            payout: payout,
            guardians: 0,
            vesting: _lockingPeriod,
            lastBlockAt: block.timestamp,
            pricePaid: priceInUSD,
            depositor: msg.sender
        });

        ownedDeposits[msg.sender].add(depositId);

        // event
        emit BondCreated(
            depositId,
            _principal,
            _amount,
            payout,
            block.timestamp + _lockingPeriod,
            priceInUSD
        );

        // increase deposit index
        depositId += 1;

        return payout;
    }

    /**
     *  @notice redeem bond for user
     *  @param _depositId uint
     *  @return uint
     */
    function redeem(
        uint256 _depositId
    ) external whenNotPaused update returns (uint256) {
        Bond memory info = bondInfo[_depositId];
        address _recipient = info.depositor;
        if (msg.sender != _recipient) revert NOT_OWNED_DEPOSIT();

        // (blocks since last interaction / vesting term remaining)
        if (percentVestedFor(_depositId) < MULTIPLIER)
            revert NOT_FULLY_VESTED();

        // update reward
        (
            RewardInfo storage rewardInfo,
            RewardInfo storage dividendsInfo
        ) = _updateReward(_depositId);
        rewardInfo.debt = (accTokenPerShare * info.guardians) / 1e18;
        dividendsInfo.debt = (dividendsPerShare * info.guardians) / 1e18;

        // delete user info
        delete bondInfo[_depositId];
        ownedDeposits[_recipient].remove(_depositId);

        // total remaining payout is decreased
        totalRemainingPayout -= info.payout;

        // send payout
        IERC20(addressProvider.getShezmu()).safeTransfer(
            _recipient,
            info.payout
        );

        // send guardians and rewards
        if (info.guardians > 0) {
            IGuardian guardian = IGuardian(addressProvider.getGuardian());
            guardian.split(_recipient, info.guardians);

            // Shezmu
            if (rewardInfo.pending > 0) {
                IERC20(addressProvider.getShezmu()).safeTransfer(
                    _recipient,
                    rewardInfo.pending
                );
                delete rewardInfoOf[_depositId];
            }

            // USDC
            if (dividendsInfo.pending > 0) {
                IERC20(guardian.USDC()).safeTransfer(
                    _recipient,
                    dividendsInfo.pending
                );
                delete dividendsInfoOf[_depositId];
            }
        }

        // event
        emit BondRedeemed(
            _depositId,
            _recipient,
            info.payout,
            info.guardians,
            0
        );

        return info.payout;
    }

    /**
     * @notice mint guardians from bond
     * @param _depositId uint
     * @param _amount uint
     */
    function mint(
        uint256 _depositId,
        address _feeToken,
        uint256 _amount
    ) external whenNotPaused update {
        Bond storage info = bondInfo[_depositId];
        address _recipient = info.depositor;
        if (msg.sender != _recipient) revert NOT_OWNED_DEPOSIT();

        // price to mint amount of guardians
        IGuardian guardian = IGuardian(addressProvider.getGuardian());
        uint256 price = guardian.pricePerGuardian() * _amount;
        if (info.payout < price) revert EXCEED_AMOUNT();

        // update reward
        (
            RewardInfo storage rewardInfo,
            RewardInfo storage dividendsInfo
        ) = _updateReward(_depositId);

        // decrease info payout
        info.payout -= price;

        // bond
        IERC20(addressProvider.getShezmu()).safeIncreaseAllowance(
            address(guardian),
            price
        );
        guardian.bond(_recipient, _feeToken, _amount);

        // increase info guardians
        info.guardians += _amount;

        // update reward debt
        rewardInfo.debt = (accTokenPerShare * info.guardians) / 1e18;
        dividendsInfo.debt = (dividendsPerShare * info.guardians) / 1e18;

        // event
        emit BondMinted(_depositId, _recipient, price, _amount);
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    function _updateReward(
        uint256 _depositId
    )
        internal
        returns (
            RewardInfo storage rewardInfo,
            RewardInfo storage dividendsInfo
        )
    {
        Bond storage info = bondInfo[_depositId];

        // Shezmu
        rewardInfo = rewardInfoOf[_depositId];
        rewardInfo.pending +=
            (accTokenPerShare * info.guardians) /
            1e18 -
            rewardInfo.debt;

        // USDC
        dividendsInfo = dividendsInfoOf[_depositId];
        dividendsInfo.pending +=
            (dividendsPerShare * info.guardians) /
            1e18 -
            dividendsInfo.debt;
    }

    function _receiveGuardianReward() internal {
        IGuardian guardian = IGuardian(addressProvider.getGuardian());
        uint256 totalGuardians = guardian.totalBalanceOf(address(this));
        if (totalGuardians == 0) return;

        IERC20 shezmu = IERC20(addressProvider.getShezmu());
        IERC20 usdc = IERC20(guardian.USDC());

        // before
        uint256 beforeShezmu = shezmu.balanceOf(address(this));
        uint256 beforeUSDC = usdc.balanceOf(address(this));

        // claim guardian reward
        guardian.claim();

        // reward of Shezmu
        uint256 reward = shezmu.balanceOf(address(this)) - beforeShezmu;
        if (reward > 0) {
            uint256 fee = (reward * guardianRewardFee) / MULTIPLIER;
            if (fee > 0) {
                shezmu.safeTransfer(addressProvider.getTreasury(), fee);
                reward -= fee;
            }
            accTokenPerShare += (reward * 1e18) / totalGuardians;
        }

        // dividends of USDC
        uint256 dividends = usdc.balanceOf(address(this)) - beforeUSDC;
        if (dividends > 0) {
            uint256 fee = (dividends * guardianRewardFee) / MULTIPLIER;
            if (fee > 0) {
                usdc.safeTransfer(addressProvider.getTreasury(), fee);
                dividends -= fee;
            }
            dividendsPerShare += (dividends * 1e18) / totalGuardians;
        }
    }

    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @return price_ uint
     */
    function bondPrice() public view returns (uint256 price_) {
        price_ = IPriceOracleAggregator(
            addressProvider.getPriceOracleAggregator()
        ).viewPriceInUSD(addressProvider.getShezmu());
    }

    /**
     *  @notice calculate interest due for new bond
     *  @param _principal address
     *  @param _amount uint
     *  @param _discount uint
     *  @return uint
     */
    function payoutFor(
        address _principal,
        uint256 _amount,
        uint256 _discount
    ) public view returns (uint256) {
        uint256 nativePrice = (bondPrice() * (MULTIPLIER - _discount)) /
            MULTIPLIER;

        return
            (_amount *
                IPriceOracleAggregator(
                    addressProvider.getPriceOracleAggregator()
                ).viewPriceInUSD(_principal) *
                UNIT) /
            (nativePrice * 10 ** IERC20Metadata(_principal).decimals());
    }

    /**
     *  @notice calculate how far into vesting a depositor is
     *  @param _depositId uint
     *  @return percentVested_ uint
     */
    function percentVestedFor(
        uint256 _depositId
    ) public view returns (uint256 percentVested_) {
        Bond memory bond = bondInfo[_depositId];
        uint256 timestampSinceLast = block.timestamp - bond.lastBlockAt;
        uint256 vesting = bond.vesting;

        if (vesting > 0) {
            percentVested_ = (timestampSinceLast * MULTIPLIER) / vesting;
        } else {
            percentVested_ = 0;
        }
    }

    /**
     *  @notice calculate amount of shezmu available for claim by depositor
     *  @param _depositId uint
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor(
        uint256 _depositId
    ) public view returns (uint256 pendingPayout_) {
        uint256 percentVested = percentVestedFor(_depositId);
        uint256 payout = bondInfo[_depositId].payout;

        if (percentVested >= MULTIPLIER) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = (payout * percentVested) / MULTIPLIER;
        }
    }

    /**
     *  @notice return minimum principal amount to deposit
     *  @param _principal address
     *  @param _discount uint
     *  @param amount_ principal amount
     */
    function minimumPrincipalAmount(
        address _principal,
        uint256 _discount
    ) external view onlyPrincipal(_principal) returns (uint256 amount_) {
        uint256 nativePrice = (bondPrice() * (MULTIPLIER - _discount)) /
            MULTIPLIER;

        amount_ =
            ((UNIT / 100) *
                nativePrice *
                10 ** IERC20Metadata(_principal).decimals()) /
            (IPriceOracleAggregator(addressProvider.getPriceOracleAggregator())
                .viewPriceInUSD(_principal) * UNIT);
    }

    /**
     *  @notice show all tokens used to create bond
     *  @return principals_ address[]
     *  @return prices_ uint256[]
     */
    function allPrincipals()
        external
        view
        returns (address[] memory principals_, uint256[] memory prices_)
    {
        principals_ = principals.values();

        uint256 length = principals.length();
        prices_ = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            prices_[i] = IPriceOracleAggregator(
                addressProvider.getPriceOracleAggregator()
            ).viewPriceInUSD(principals.at(i));
        }
    }

    /**
     *  @notice show all locking periods and discounts
     *  @return lockingPeriods_ locking periods
     *  @return lockingDiscounts_ locking discounts
     */
    function allLockingPeriodsDiscounts()
        external
        view
        returns (
            uint256[] memory lockingPeriods_,
            uint256[] memory lockingDiscounts_
        )
    {
        lockingPeriods_ = lockingPeriods;

        uint256 length = lockingPeriods.length;
        lockingDiscounts_ = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            lockingDiscounts_[i] = lockingDiscounts[lockingPeriods[i]];
        }
    }

    /**
     *  @notice show all bond infos for a particular owner
     *  @param _owner address
     *  @return bondInfos_ Bond[]
     *  @return rewardInfos_ uint256[]
     *  @return dividendsInfos_ uint256[]
     */
    function allBondInfos(
        address _owner
    )
        external
        view
        returns (
            Bond[] memory bondInfos_,
            uint256[] memory rewardInfos_,
            uint256[] memory dividendsInfos_
        )
    {
        uint256 accTokenPerShare_ = accTokenPerShare;
        uint256 dividendsPerShare_ = dividendsPerShare;

        // calculate reward rate
        {
            IGuardian guardian = IGuardian(addressProvider.getGuardian());
            uint256 totalGuardians = guardian.totalBalanceOf(address(this));

            if (totalGuardians > 0) {
                (uint256 reward, uint256 dividends) = guardian.pendingReward(
                    address(this)
                );

                reward -= (reward * guardianRewardFee) / MULTIPLIER;
                dividends -= (dividends * guardianRewardFee) / MULTIPLIER;

                accTokenPerShare_ += (reward * 1e18) / totalGuardians;
                dividendsPerShare_ += (dividends * 1e18) / totalGuardians;
            }
        }

        // return
        uint256 length = ownedDeposits[_owner].length();
        bondInfos_ = new Bond[](length);
        rewardInfos_ = new uint256[](length);
        dividendsInfos_ = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            uint256 depositId_ = ownedDeposits[_owner].at(i);
            Bond memory info = bondInfo[depositId_];
            RewardInfo memory rewardInfo = rewardInfoOf[depositId_];
            RewardInfo memory dividendsInfo = dividendsInfoOf[depositId_];

            bondInfos_[i] = bondInfo[depositId_];
            rewardInfos_[i] =
                rewardInfo.pending +
                (accTokenPerShare_ * info.guardians) /
                1e18 -
                rewardInfo.debt;
            dividendsInfos_[i] =
                dividendsInfo.pending +
                (dividendsPerShare_ * info.guardians) /
                1e18 -
                dividendsInfo.debt;
        }
    }

    uint256[49] private __gap;
}
