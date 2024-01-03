/*
https://powerpool.finance/
          wrrrw r wrr
         ppwr rrr wppr0       prwwwrp                                 prwwwrp                   wr0
        rr 0rrrwrrprpwp0      pp   pr  prrrr0 pp   0r  prrrr0  0rwrrr pp   pr  prrrr0  prrrr0    r0
        rrp pr   wr00rrp      prwww0  pp   wr pp w00r prwwwpr  0rw    prwww0  pp   wr pp   wr    r0
        r0rprprwrrrp pr0      pp      wr   pr pp rwwr wr       0r     pp      wr   pr wr   pr    r0
         prwr wrr0wpwr        00        www0   0w0ww    www0   0w     00        www0    www0   0www0
          wrr ww0rrrr
*/
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;

import "./Initializable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IPowerOracleStaking.sol";
import "./IPowerOracle.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract PowerOracleStaking is IPowerOracleStaking, Ownable, Initializable, Pausable {
  using SafeMath for uint256;

  uint256 public constant HUNDRED_PCT = 100 ether;

  /// @notice The event emitted when a new user is created
  event CreateUser(uint256 indexed userId, address indexed adminKey, address indexed pokerKey, uint256 initialDeposit);

  /// @notice The event emitted when an existing user is updated
  event UpdateUser(uint256 indexed userId, address indexed adminKey, address indexed pokerKey);

  /// @notice The event emitted when an existing user is updated
  event Deposit(uint256 indexed userId, address indexed depositor, uint256 amount, uint256 depositAfter);

  /// @notice The event emitted when a valid admin key withdraws funds deposited for the given user ID
  event Withdraw(
    uint256 indexed userId,
    address indexed adminKey,
    address indexed to,
    uint256 amount,
    uint256 depositAfter
  );

  /// @notice The event emitted when the owner withdraws the extra CVP amount from the contract
  event WithdrawExtraCVP(
    bool indexed sent,
    address indexed to,
    uint256 diff,
    uint256 erc20Balance,
    uint256 accountedTotalDeposits
  );

  /// @notice The event emitted when the owner sets a new minimal slashing deposit value
  event SetMinimalSlashingDeposit(uint256 amount);

  /// @notice The event emitted when the owner sets new slashing percent values, where 1ether == 1%
  event SetSlashingPct(uint256 slasherSlashingRewardPct, uint256 protocolSlashingRewardPct);

  /// @notice The event emitted when the owner sets a new PowerOracle linked contract
  event SetPowerOracle(address powerOracle);

  /// @notice The event emitted when an arbitrary user fixes an outdated reporter userId record
  event SetReporter(uint256 indexed reporterId, address indexed msgSender);

  /// @notice The event emitted when the PowerOracle contract requests to slash a user with the given ID
  event Slash(
    uint256 indexed slasherId,
    uint256 indexed reporterId,
    uint256 indexed overdueCount,
    uint256 slasherReward,
    uint256 reservoirReward
  );

  /// @notice The event emitted when the existing reporter is replaced with a new one due some reason
  event ReporterChange(
    uint256 indexed prevId,
    uint256 indexed nextId,
    uint256 highestDepositPrev,
    uint256 actualDepositPrev,
    uint256 actualDepositNext
  );

  struct User {
    address adminKey;
    address pokerKey;
    uint256 deposit;
  }

  /// @notice CVP token address
  IERC20 public immutable cvpToken;

  /// @notice The reservoir which holds CVP tokens
  address public immutable reservoir;

  /// @notice The PowerOracle contract
  address public powerOracle;

  /// @notice The total amount of all deposits
  uint256 public totalDeposit;

  /// @notice The minimal slashing deposit to make a registered user a valid slasher
  uint256 public minimalSlashingDeposit;

  /// @notice The share of a slasher in slashed deposit per one outdated asset (1 eth == 1%)
  uint256 public slasherSlashingRewardPct;

  /// @notice The share of the protocol(reservoir) in slashed deposit per one outdated asset (1 eth == 1%)
  uint256 public protocolSlashingRewardPct;

  /// @notice The incremented user ID counter. Is updated only within createUser function call
  uint256 public userIdCounter;

  /// @dev The highest deposit. Usually of the current reporterId. Is safe to be outdated.
  uint256 internal _highestDeposit;

  /// @dev The current reporter user ID.
  uint256 internal _reporterId;

  /// @notice User details by it's ID
  mapping(uint256 => User) public users;

  constructor(address cvpToken_, address reservoir_) public {
    cvpToken = IERC20(cvpToken_);
    reservoir = reservoir_;
  }

  function initialize(
    address owner_,
    address powerOracle_,
    uint256 minimalSlashingDeposit_,
    uint256 slasherRewardPct_,
    uint256 reservoirSlashingRewardPct_
  ) public initializer {
    _transferOwnership(owner_);
    powerOracle = powerOracle_;
    minimalSlashingDeposit = minimalSlashingDeposit_;
    slasherSlashingRewardPct = slasherRewardPct_;
    protocolSlashingRewardPct = reservoirSlashingRewardPct_;
  }

  /*** User Interface ***/

  /**
   * @notice An arbitrary user deposits CVP stake to the contract for the given user ID
   * @param userId_ The user ID to make deposit for
   * @param amount_ The amount in CVP tokens to deposit
   */
  function deposit(uint256 userId_, uint256 amount_) external override whenNotPaused {
    require(amount_ > 0, "PowerOracleStaking::deposit: Missing amount");
    require(users[userId_].adminKey != address(0), "PowerOracleStaking::deposit: Admin key can't be empty");

    _deposit(userId_, amount_);
  }

  function _deposit(uint256 userId_, uint256 amount_) internal {
    User storage user = users[userId_];

    uint256 depositAfter = user.deposit.add(amount_);
    user.deposit = depositAfter;
    totalDeposit = totalDeposit.add(amount_);

    _trySetReporter(userId_, depositAfter);

    emit Deposit(userId_, msg.sender, amount_, depositAfter);
    cvpToken.transferFrom(msg.sender, address(this), amount_);
  }

  function _trySetReporter(uint256 candidateId_, uint256 candidateDepositAfter_) internal {
    uint256 prevReporterId = _reporterId;
    uint256 prevDeposit = users[prevReporterId].deposit;

    if (candidateDepositAfter_ > prevDeposit && prevReporterId != candidateId_) {
      emit ReporterChange(
        prevReporterId,
        candidateId_,
        _highestDeposit,
        users[prevReporterId].deposit,
        candidateDepositAfter_
      );

      _highestDeposit = candidateDepositAfter_;
      _reporterId = candidateId_;
    }
  }

  /**
   * @notice A valid users admin key withdraws the deposited stake form the contract
   * @param userId_ The user ID to withdraw deposit from
   * @param to_ The address to send the CVP tokens to
   * @param amount_ The amount in CVP tokens to withdraw
   */
  function withdraw(
    uint256 userId_,
    address to_,
    uint256 amount_
  ) external override {
    require(amount_ > 0, "PowerOracleStaking::withdraw: Missing amount");
    require(to_ != address(0), "PowerOracleStaking::withdraw: Can't transfer to 0 address");

    User storage user = users[userId_];
    require(msg.sender == user.adminKey, "PowerOracleStaking::withdraw: Only user's admin key allowed");

    uint256 depositBefore = user.deposit;
    require(amount_ <= depositBefore, "PowerOracleStaking::withdraw: Amount exceeds deposit");

    uint256 depositAfter = depositBefore - amount_;
    users[userId_].deposit = depositAfter;
    totalDeposit = totalDeposit.sub(amount_);

    emit Withdraw(userId_, msg.sender, to_, amount_, depositAfter);
    cvpToken.transfer(to_, amount_);
  }

  /**
   * @notice Creates a new user ID and stores the given keys
   * @param adminKey_ The admin key for the new user
   * @param pokerKey_ The poker key for the new user
   * @param initialDeposit_ The initial deposit to be transferred to this contract
   */
  function createUser(
    address adminKey_,
    address pokerKey_,
    uint256 initialDeposit_
  ) external override whenNotPaused {
    uint256 userId = ++userIdCounter;

    users[userId] = User(adminKey_, pokerKey_, 0);

    emit CreateUser(userId, adminKey_, pokerKey_, initialDeposit_);

    if (initialDeposit_ > 0) {
      _deposit(userId, initialDeposit_);
    }
  }

  /**
   * @notice Updates an existing user, only the current adminKey is eligible calling this method.
   * @param adminKey_ The new admin key for the user
   * @param pokerKey_ The new poker key for the user
   */
  function updateUser(
    uint256 userId_,
    address adminKey_,
    address pokerKey_
  ) external override {
    User storage user = users[userId_];
    require(msg.sender == user.adminKey, "PowerOracleStaking::updateUser: Only admin allowed");

    if (adminKey_ != user.adminKey) {
      user.adminKey = adminKey_;
    }
    if (pokerKey_ != user.pokerKey) {
      user.pokerKey = pokerKey_;
    }

    emit UpdateUser(userId_, adminKey_, pokerKey_);
  }

  /*** PowerOracle Contract Interface ***/

  /**
   * @notice Slashes the current reporter if it did not make poke() call during the given report interval
   * @param slasherId_ The slasher ID
   * @param overdueCount_ The overdue token multiplier
   */
  function slash(uint256 slasherId_, uint256 overdueCount_) external virtual override {
    User storage slasher = users[slasherId_];
    require(slasher.deposit >= minimalSlashingDeposit, "PowerOracleStaking::slash: Insufficient slasher deposit");
    require(msg.sender == powerOracle, "PowerOracleStaking::slash: Only PowerOracle allowed");

    uint256 reporterId = _reporterId;
    uint256 reporterDeposit = users[reporterId].deposit;

    uint256 product = overdueCount_.mul(reporterDeposit);
    // uint256 slasherReward = overdueCount_ * reporterDeposit * slasherRewardPct / HUNDRED_PCT;
    uint256 slasherReward = product.mul(slasherSlashingRewardPct) / HUNDRED_PCT;
    // uint256 reservoirReward = overdueCount_ * reporterDeposit * reservoirSlashingRewardPct / HUNDRED_PCT;
    uint256 reservoirReward = product.mul(protocolSlashingRewardPct) / HUNDRED_PCT;

    // users[reporterId].deposit = reporterDeposit - slasherReward - reservoirReward;
    users[reporterId].deposit = reporterDeposit.sub(slasherReward).sub(reservoirReward);

    // totalDeposit = totalDeposit - reservoirReward;
    totalDeposit = totalDeposit.sub(reservoirReward);

    emit Slash(slasherId_, reporterId, overdueCount_, slasherReward, reservoirReward);

    if (slasherReward > 0) {
      // uint256 slasherDepositAfter = users[slasherId_].deposit + slasherReward
      uint256 slasherDepositAfter = users[slasherId_].deposit.add(slasherReward);
      users[slasherId_].deposit = slasherDepositAfter;
      _trySetReporter(slasherId_, slasherDepositAfter);
    }

    if (reservoirReward > 0) {
      cvpToken.transfer(reservoir, reservoirReward);
    }
  }

  /*** Owner Interface ***/

  /**
   * @notice The owner withdraws the surplus of CVP tokens
   * @param to_ The address to transfer the surplus
   */
  function withdrawExtraCVP(address to_) external override onlyOwner {
    require(to_ != address(0), "PowerOracleStaking::withdrawExtraCVP: Cant withdraw to 0 address");

    uint256 erc20Balance = cvpToken.balanceOf(address(this));
    uint256 totalBalance = totalDeposit;
    bool sent = false;
    uint256 diff;

    if (erc20Balance > totalBalance) {
      diff = erc20Balance - totalBalance;

      cvpToken.transfer(to_, diff);
      sent = true;
    }

    emit WithdrawExtraCVP(sent, to_, diff, erc20Balance, totalBalance);
  }

  /**
   * @notice The owner sets a new minimal slashing deposit value
   * @param amount_ The minimal slashing deposit in CVP tokens
   */
  function setMinimalSlashingDeposit(uint256 amount_) external override onlyOwner {
    minimalSlashingDeposit = amount_;
    emit SetMinimalSlashingDeposit(amount_);
  }

  /**
   * @notice The owner sets a new powerOracle address
   * @param powerOracle_ The powerOracle address to set
   */
  function setPowerOracle(address powerOracle_) external override onlyOwner {
    powerOracle = powerOracle_;
    emit SetPowerOracle(powerOracle_);
  }

  /**
   * @notice The owner sets the new slashing percent values
   * @param slasherSlashingRewardPct_ The slasher share will be accrued on the slasher's deposit
   * @param protocolSlashingRewardPct_ The protocol share will immediately be transferred to reservoir
   */
  function setSlashingPct(uint256 slasherSlashingRewardPct_, uint256 protocolSlashingRewardPct_)
    external
    override
    onlyOwner
  {
    require(
      slasherSlashingRewardPct_.add(protocolSlashingRewardPct_) <= HUNDRED_PCT,
      "PowerOracleStaking::setSlashingPct: Invalid reward sum"
    );

    slasherSlashingRewardPct = slasherSlashingRewardPct_;
    protocolSlashingRewardPct = protocolSlashingRewardPct_;
    emit SetSlashingPct(slasherSlashingRewardPct_, protocolSlashingRewardPct_);
  }

  /**
   * @notice The owner pauses poke*-operations
   */
  function pause() external override onlyOwner {
    _pause();
  }

  /**
   * @notice The owner unpauses poke*-operations
   */
  function unpause() external override onlyOwner {
    _unpause();
  }

  /*** Permissionless Interface ***/

  /**
   * @notice Set a given address as a reporter if his deposit is higher than the current highestDeposit
   * @param candidateId_ Te candidate address to try
   */
  function setReporter(uint256 candidateId_) external override {
    uint256 candidateDeposit = users[candidateId_].deposit;
    uint256 prevReporterId = _reporterId;
    uint256 currentReporterDeposit = users[prevReporterId].deposit;

    require(
      candidateDeposit > currentReporterDeposit,
      "PowerOracleStaking::setReporter: Insufficient candidate deposit"
    );

    emit ReporterChange(prevReporterId, candidateId_, _highestDeposit, currentReporterDeposit, candidateDeposit);
    emit SetReporter(candidateId_, msg.sender);

    _highestDeposit = candidateDeposit;
    _reporterId = candidateId_;
  }

  /*** Viewers ***/

  function getReporterId() external view override returns (uint256) {
    return _reporterId;
  }

  function getHighestDeposit() external view override returns (uint256) {
    return _highestDeposit;
  }

  function getDepositOf(uint256 userId_) external view override returns (uint256) {
    return users[userId_].deposit;
  }

  function getUserStatus(uint256 userId_, address pokerKey) external view override returns (UserStatus) {
    if (userId_ == _reporterId && users[userId_].pokerKey == pokerKey) {
      return UserStatus.CAN_REPORT;
    }
    if (users[userId_].deposit >= minimalSlashingDeposit && users[userId_].pokerKey == pokerKey) {
      return UserStatus.CAN_SLASH;
    }
    return UserStatus.UNAUTHORIZED;
  }

  function authorizeReporter(uint256 userId_, address pokerKey_) external view override {
    require(userId_ == _reporterId, "PowerOracleStaking::authorizeReporter: Invalid reporter");
    require(users[userId_].pokerKey == pokerKey_, "PowerOracleStaking::authorizeReporter: Invalid poker key");
  }

  function authorizeSlasher(uint256 userId_, address pokerKey_) external view override {
    require(
      users[userId_].deposit >= minimalSlashingDeposit,
      "PowerOracleStaking::authorizeSlasher: Insufficient deposit"
    );
    require(users[userId_].pokerKey == pokerKey_, "PowerOracleStaking::authorizeSlasher: Invalid poker key");
  }

  function requireValidAdminKey(uint256 userId_, address adminKey_) external view override {
    require(users[userId_].adminKey == adminKey_, "PowerOracleStaking::requireValidAdminKey: Invalid admin key");
  }
}
