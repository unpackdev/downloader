// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Initializable.sol";
import "./IBaseReward.sol";

// Reference @openzeppelin/contracts/token/ERC20/IERC20.sol
interface ILendFlareVotingEscrow {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
}

contract LendFlareVotingEscrow is
    Initializable,
    ReentrancyGuard,
    ILendFlareVotingEscrow
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 constant WEEK = 1 weeks; // all future times are rounded by week
    uint256 constant MAXTIME = 4 * 365 * 86400; // 4 years
    string constant NAME = "Vote-escrowed LFT";
    string constant SYMBOL = "VeLFT";
    uint8 constant DECIMALS = 18;

    address public token;
    address public rewardManager;

    uint256 public override totalSupply;

    enum DepositTypes {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME
    }

    struct Point {
        uint256 bias;
        uint256 slope; // dweight / dt
        uint256 ts; // timestamp
    }

    struct LockedBalance {
        uint256 amount;
        uint256 end;
    }

    IBaseReward[] public rewardPools;

    mapping(address => LockedBalance) public lockedBalances;
    mapping(address => mapping(uint256 => Point)) public userPointHistory; // user => ( user epoch => point )
    mapping(address => uint256) public userPointEpoch; // user => user epoch

    event Deposit(
        address indexed provider,
        uint256 value,
        uint256 indexed locktime,
        DepositTypes depositTypes,
        uint256 ts
    );
    event Withdraw(address indexed provider, uint256 value, uint256 ts);
    event TotalSupply(uint256 prevSupply, uint256 supply);

    // @custom:oz-upgrades-unsafe-allow constructor
    constructor() public initializer {}

    function initialize(address _token, address _rewardManager)
        public
        initializer
    {
        token = _token;
        rewardManager = _rewardManager;
    }

    modifier onlyRewardManager() {
        require(
            rewardManager == msg.sender,
            "LendFlareVotingEscrow: caller is not the rewardManager"
        );
        _;
    }

    function rewardPoolsLength() external view returns (uint256) {
        return rewardPools.length;
    }

    function addRewardPool(address _v)
        external
        onlyRewardManager
        returns (bool)
    {
        require(_v != address(0), "!_v");

        rewardPools.push(IBaseReward(_v));

        return true;
    }

    function clearRewardPools() external onlyRewardManager {
        delete rewardPools;
    }

    function _checkpoint(address _sender, LockedBalance storage _newLocked)
        internal
    {
        Point storage point = userPointHistory[_sender][
            ++userPointEpoch[_sender]
        ];

        point.ts = block.timestamp;

        if (_newLocked.end > block.timestamp) {
            point.slope = _newLocked.amount.div(MAXTIME);
            point.bias = point.slope.mul(_newLocked.end.sub(block.timestamp));
        }
    }

    function _depositFor(
        address _sender,
        uint256 _amount,
        uint256 _unlockTime,
        LockedBalance storage _locked,
        DepositTypes _depositTypes
    ) internal {
        uint256 oldTotalSupply = totalSupply;

        if (_amount > 0) {
            IERC20(token).safeTransferFrom(_sender, address(this), _amount);
        }

        _locked.amount = _locked.amount.add(_amount);
        totalSupply = totalSupply.add(_amount);

        if (_unlockTime > 0) {
            _locked.end = _unlockTime;
        }

        for (uint256 i = 0; i < rewardPools.length; i++) {
            rewardPools[i].stake(_sender);
        }

        _checkpoint(_sender, _locked);

        emit Deposit(
            _sender,
            _amount,
            _locked.end,
            _depositTypes,
            block.timestamp
        );
        emit TotalSupply(oldTotalSupply, totalSupply);
    }

    function deposit(uint256 _amount) external nonReentrant {
        LockedBalance storage locked = lockedBalances[msg.sender];

        require(_amount > 0, "need non-zero value");
        require(locked.amount > 0, "no existing lock found");
        require(
            locked.end > block.timestamp,
            "cannot add to expired lock. Withdraw"
        );

        _depositFor(
            msg.sender,
            _amount,
            0,
            locked,
            DepositTypes.DEPOSIT_FOR_TYPE
        );
    }

    function createLock(uint256 _amount, uint256 _unlockTime)
        external
        nonReentrant
    {
        LockedBalance storage locked = lockedBalances[msg.sender];
        uint256 availableTime = formatWeekTs(_unlockTime);

        require(_amount > 0, "need non-zero value");
        require(locked.amount == 0, "Withdraw old tokens first");
        require(
            availableTime > block.timestamp,
            "can only lock until time in the future"
        );
        require(
            availableTime <= block.timestamp + MAXTIME,
            "voting lock can be 4 years max"
        );

        _depositFor(
            msg.sender,
            _amount,
            availableTime,
            locked,
            DepositTypes.CREATE_LOCK_TYPE
        );
    }

    function increaseAmount(uint256 _amount) external nonReentrant {
        LockedBalance storage locked = lockedBalances[msg.sender];
        require(_amount > 0, "need non-zero value");
        require(locked.amount > 0, "No existing lock found");
        require(
            locked.end > block.timestamp,
            "Cannot add to expired lock. Withdraw"
        );

        _depositFor(
            msg.sender,
            _amount,
            0,
            locked,
            DepositTypes.INCREASE_LOCK_AMOUNT
        );
    }

    function increaseUnlockTime(uint256 _unlockTime) external nonReentrant {
        LockedBalance storage locked = lockedBalances[msg.sender];
        uint256 availableTime = formatWeekTs(_unlockTime);

        require(locked.end > block.timestamp, "Lock expired");
        require(locked.amount > 0, "Nothing is locked");
        require(availableTime > locked.end, "Can only increase lock duration");
        require(
            availableTime <= block.timestamp + MAXTIME,
            "Voting lock can be 4 years max"
        );

        _depositFor(
            msg.sender,
            0,
            availableTime,
            locked,
            DepositTypes.INCREASE_UNLOCK_TIME
        );
    }

    function withdraw() public nonReentrant {
        LockedBalance storage locked = lockedBalances[msg.sender];

        require(block.timestamp >= locked.end, "The lock didn't expire");

        uint256 oldTotalSupply = totalSupply;
        uint256 lockedAmount = locked.amount;

        totalSupply = totalSupply.sub(lockedAmount);

        locked.amount = 0;
        locked.end = 0;

        _checkpoint(msg.sender, locked);

        IERC20(token).safeTransfer(msg.sender, lockedAmount);

        for (uint256 i = 0; i < rewardPools.length; i++) {
            rewardPools[i].withdraw(msg.sender);
        }

        emit Withdraw(msg.sender, lockedAmount, block.timestamp);
        emit TotalSupply(oldTotalSupply, totalSupply);
    }

    function formatWeekTs(uint256 _unixTime) public pure returns (uint256) {
        return _unixTime.div(WEEK).mul(WEEK);
    }

    function balanceOf(address _sender)
        external
        view
        override
        returns (uint256)
    {
        uint256 userEpoch = userPointEpoch[_sender];

        if (userEpoch == 0) return 0;

        Point storage point = userPointHistory[_sender][userEpoch];

        return point.bias.sub(point.slope.mul(block.timestamp.sub(point.ts)));
    }

    function name() public pure returns (string memory) {
        return NAME;
    }

    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }
}
