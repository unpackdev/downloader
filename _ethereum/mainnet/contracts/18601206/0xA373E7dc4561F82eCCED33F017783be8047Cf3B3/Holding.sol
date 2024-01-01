// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Ownable2StepUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

import "./IERC20.sol";

interface IAirdrop {
    function claim(address account, uint256 amount, bytes32[] memory proof) external;
}

contract Holding is UUPSUpgradeable, Ownable2StepUpgradeable, PausableUpgradeable {
    mapping(address => uint256) internal _balances;
    mapping(address => uint256) internal _points;
    mapping(address => uint256) public lastUpdatedAt;
    mapping(address => uint256) public multiplierStart;

    uint256 public holdingStartTime;
    uint256 public holdingEndTime;

    IAirdrop public airdrop;

    IERC20 public immutable TOKEN;

    uint256 private constant _HOUR = 3_600;
    uint256 private constant _DAY = _HOUR * 24;
    uint256 private constant _MONTH = _DAY * 30;
    uint256 private constant _EARLY_HOLDING_BONUS_PERIOD = 6; // days

    uint256 private constant _BASIS_POINTS = 10_000;
    uint256 private constant _MULTIPLIER_PER_MONTH = 5_000; // bips
    uint256 private constant _EARLY_HOLDING_BONUS_PER_DAY = 5_000; // bips / hour
    uint256 private constant _BASE_MULTIPLIER = 10_000; // bips

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    error InsufficientBalance();

    constructor(address token) {
        _disableInitializers();
        TOKEN = IERC20(token);
    }

    function initialize() external initializer {
        __Ownable2Step_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        _pause();

        holdingEndTime = type(uint256).max;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /*//////////////////////////////
            ADMIN FUNCTIONS
    //////////////////////////////*/

    /**
     * @notice Initiate the holding period (admin only)
     * @param _airdrop Airdrop contract address
     */
    function startHolding(address _airdrop) external onlyOwner {
        require(holdingStartTime == 0);
        airdrop = IAirdrop(_airdrop);
        holdingStartTime = block.timestamp;
        _unpause();
    }

    /**
     * @notice End the holding period (admin only)
     */
    function endHolding() external onlyOwner {
        require(holdingStartTime != 0 && holdingEndTime == type(uint256).max);
        holdingEndTime = block.timestamp;
        _pause();
    }

    /**
     * @notice Pause deposits (admin only)
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause deposits (admin only)
     */
    function unpause() external onlyOwner {
        require(holdingStartTime != 0 && holdingEndTime == type(uint256).max);
        _unpause();
    }

    /*//////////////////////////////
                 VIEWS
    //////////////////////////////*/

    /**
     * @notice Gets the balance of the user deposits
     * @param user User address
     * @return User deposit balance
     */
    function balanceOf(address user) external view returns (uint256) {
        return _balances[user];
    }

    /**
     * @notice Gets the current amount of points earned by the user (including pending points)
     * @param user User address
     * @return User points
     */
    function pointsOf(address user) public view returns (uint256) {
        return _points[user] + _computePendingPoints(user);
    }

    /**
     * @notice Gets the current points multiplier of the user
     * @param user User address
     * @return User multiplier
     */
    function multiplierOf(address user) public view returns (uint256) {
        uint256 _multiplierStart = multiplierStart[user];
        if (_multiplierStart == 0 || _balances[user] == 0) {
            return _BASE_MULTIPLIER;
        }
        return
            _BASE_MULTIPLIER +
            (_MULTIPLIER_PER_MONTH * (min(block.timestamp, holdingEndTime) - _multiplierStart)) /
            _MONTH;
    }

    /**
     * @notice Gets the current score of the user
     * @param user User address
     * @return User score
     */
    function scoreOf(address user) external view returns (uint256) {
        return (pointsOf(user) * multiplierOf(user)) / _BASIS_POINTS;
    }

    /*//////////////////////////////
        DEPOSITS AND WITHDRAWS 
    //////////////////////////////*/

    /**
     * @notice Deposit TOKEN
     * @param amount Amount of TOKEN to deposit
     */
    function deposit(uint256 amount) external {
        require(amount > 0);
        _deposit(msg.sender, amount);

        TOKEN.transferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice Deposit TOKEN from airdrop claim; rewards airdrop recipient bonus of 2 months multiplier head start
     * @param user Airdrop user address
     * @param amount Airdrop TOKEN amount
     * @param proof Airdrop claim proof
     */
    function depositFromAirdrop(address user, uint256 amount, bytes32[] calldata proof) external {
        airdrop.claim(user, amount, proof);
        _deposit(user, amount);
        multiplierStart[user] -= _MONTH * 2; // grant two month headstart as a bonus
    }

    /**
     * @notice Withdraw TOKEN and enforce multiplier penalty
     * @param amount Amount to withdraw
     */
    function withdraw(uint256 amount) external {
        _checkpoint(msg.sender);

        uint256 balance = _balances[msg.sender];
        if (balance < amount) {
            revert InsufficientBalance();
        }
        _decreaseMultiplier(msg.sender, amount);
        unchecked {
            _balances[msg.sender] = balance - amount;
        }

        TOKEN.transfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }

    /**
     * @notice Deposit TOKEN from user
     * @param user User address
     * @param amount Amount of TOKEN to deposit
     */
    function _deposit(address user, uint256 amount) internal whenNotPaused {
        if (multiplierStart[user] == 0) {
            multiplierStart[user] = block.timestamp;
        }
        if (lastUpdatedAt[user] == 0) {
            lastUpdatedAt[user] = block.timestamp;
        }
        _checkpoint(user);

        _balances[user] += amount;

        emit Deposit(user, amount);
    }

    /**
     * @notice Record earned points and update the last checkpoint time; must be called on every deposit and withdrawal
     * @param user User address
     */
    function _checkpoint(address user) internal {
        _points[user] += _computePendingPoints(user);
        lastUpdatedAt[user] = block.timestamp;
    }

    /**
     * @notice Compute the pending points that have been earned but not recorded since the last checkpoint
     * @param user User address
     * @return points Amount of earned unrecorded points
     */
    function _computePendingPoints(address user) internal view returns (uint256) {
        uint256 _holdingEndTime = holdingEndTime;
        uint256 start = min(lastUpdatedAt[user], _holdingEndTime);
        uint256 end = min(block.timestamp, _holdingEndTime);
        return
            (_balances[user] * (_BASIS_POINTS * (end - start) + _earlyHolderBonus(start, end))) /
            (_HOUR * _BASIS_POINTS);
    }

    /**
     * @notice Penalize mutiplier for early withdrawal by increasing the multiplier start time
     * @dev Penalty is equal to the portion of the balance being withdrawn; balance should be decreased AFTER this function
     * @param user User address
     * @param amount Withdrawal amount
     */
    function _decreaseMultiplier(address user, uint256 amount) internal {
        uint256 balance = _balances[user];
        if (block.timestamp < holdingEndTime) {
            if (amount == balance) {
                multiplierStart[user] = 0;
            } else {
                uint256 _multiplierStart = multiplierStart[user];
                uint256 penaltyTime = (amount * (block.timestamp - _multiplierStart)) / balance;
                multiplierStart[user] = _multiplierStart + penaltyTime;
            }
        }
    }

    /**
     * @notice Compute the bonus points rate for early holders
     * @param start Staking start time
     * @param end Staking end time
     * @return pointsPerTokenPerSecond
     */
    function _earlyHolderBonus(
        uint256 start,
        uint256 end
    ) internal view returns (uint256 pointsPerTokenPerSecond) {
        if (start < _EARLY_HOLDING_BONUS_PERIOD * _DAY + holdingStartTime && start >= holdingStartTime) {
            uint256 startDay = (start - holdingStartTime) / _DAY;
            uint256 endDay = min((end - holdingStartTime) / _DAY, _EARLY_HOLDING_BONUS_PERIOD - 1);

            uint256 lastUpdated;
            uint256 nextUpdated = start;
            uint256 intervalMultiplier = (_EARLY_HOLDING_BONUS_PERIOD - startDay) *
                _EARLY_HOLDING_BONUS_PER_DAY;
            for (uint256 i = startDay; i <= endDay; i++) {
                lastUpdated = nextUpdated;
                nextUpdated = min(end, (i + 1) * _DAY + holdingStartTime);
                pointsPerTokenPerSecond += intervalMultiplier * (nextUpdated - lastUpdated);
                intervalMultiplier -= _EARLY_HOLDING_BONUS_PER_DAY;
            }
        }
    }

    /*////////////////////////////
           HELPER FUNCTIONS
    ////////////////////////////*/

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
