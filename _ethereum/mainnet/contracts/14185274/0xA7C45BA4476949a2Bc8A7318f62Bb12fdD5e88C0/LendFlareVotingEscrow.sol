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

contract LendFlareVotingEscrow is Initializable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 constant WEEK = 1 weeks; // all future times are rounded by week
    uint256 constant MAXTIME = 4 * 365 * 86400; // 4 years
    uint256 constant MULTIPLIER = 10**18;

    uint256 private _totalSupply;

    string private constant _name = "Vote-escrowed LFT";
    string private constant _symbol = "VeLFT";
    uint8 private constant _decimals = 18;
    string private _version;
    address public token;
    uint256 public epoch;

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
        uint256 blk; // block number
    }

    struct LockedBalance {
        uint256 amount;
        uint256 end;
    }

    IBaseReward[] public reward_pools;

    mapping(uint256 => Point) public point_history; // epoch -> unsigned point
    mapping(address => mapping(uint256 => Point)) public user_point_history; // user -> Point[user_epoch]
    mapping(address => uint256) public user_point_epoch;
    mapping(uint256 => uint256) public slope_changes; // time -> signed slope change
    mapping(address => LockedBalance) public locked;

    address public owner;

    event Deposit(
        address indexed provider,
        uint256 value,
        uint256 indexed locktime,
        DepositTypes depositTypes,
        uint256 ts
    );
    event Withdraw(address indexed provider, uint256 value, uint256 ts);
    event Supply(uint256 prevSupply, uint256 supply);
    event SetMinter(address minter);
    event SetOwner(address owner);

    function initialize(
        string memory version_,
        address token_addr_,
        address owner_
    ) public initializer {
        _version = version_;
        token = token_addr_;
        owner = owner_;
    }

    modifier onlyOwner() {
        require(
            owner == msg.sender,
            "LendFlareVotingEscrow: caller is not the owner"
        );
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;

        emit SetOwner(_owner);
    }

    function rewardPoolsLength() external view returns (uint256) {
        return reward_pools.length;
    }

    function addRewardPool(address _v) external onlyOwner returns (bool) {
        require(_v != address(0), "!_v");

        reward_pools.push(IBaseReward(_v));

        return true;
    }

    function clearRewardPools() external onlyOwner {
        delete reward_pools;
    }

    function getLastUserSlope(address addr) external view returns (uint256) {
        uint256 uepoch = user_point_epoch[addr];

        return user_point_history[addr][uepoch].slope;
    }

    function userPointHistoryTs(address _addr, uint256 _idx)
        external
        view
        returns (uint256)
    {
        return user_point_history[_addr][_idx].ts;
    }

    function lockedEnd(address _addr) external view returns (uint256) {
        return locked[_addr].end;
    }

    function _checkpoint(
        address addr,
        LockedBalance memory old_locked,
        LockedBalance storage new_locked
    ) internal {
        Point memory u_old;
        Point memory u_new;
        uint256 old_dslope = 0;
        uint256 new_dslope = 0;

        if (addr != address(0)) {
            if (old_locked.end > block.timestamp && old_locked.amount > 0) {
                u_old.slope = old_locked.amount / MAXTIME;
                u_old.bias = u_old.slope * (old_locked.end - block.timestamp);
            }

            if (new_locked.end > block.timestamp && new_locked.amount > 0) {
                u_new.slope = new_locked.amount / MAXTIME;
                u_new.bias = u_new.slope * (new_locked.end - block.timestamp);
            }

            old_dslope = slope_changes[old_locked.end];

            if (new_locked.end != 0) {
                if (new_locked.end == old_locked.end) new_dslope = old_dslope;
                else new_dslope = slope_changes[new_locked.end];
            }
        }

        Point memory last_point = Point({
            bias: 0,
            slope: 0,
            ts: block.timestamp,
            blk: block.number
        });

        if (epoch > 0) {
            last_point = point_history[epoch];
        }

        uint256 last_checkpoint = last_point.ts;
        Point memory initial_last_point = last_point;
        uint256 block_slope = 0; // dblock/dt

        if (block.timestamp > last_point.ts) {
            block_slope =
                (MULTIPLIER * (block.number - last_point.blk)) /
                (block.timestamp - last_point.ts);
        }

        uint256 t_i = (last_checkpoint / WEEK) * WEEK;

        for (uint256 i = 0; i < 255; i++) {
            uint256 d_slope = 0;
            t_i += WEEK;

            if (t_i > block.timestamp) t_i = block.timestamp;
            else d_slope = slope_changes[t_i];

            last_point.bias -= last_point.slope * (t_i - last_checkpoint);
            last_point.slope += d_slope;

            if (last_point.bias < 0) last_point.bias = 0;

            if (last_point.slope < 0) last_point.slope = 0;

            last_checkpoint = t_i;
            last_point.ts = t_i;
            last_point.blk =
                initial_last_point.blk +
                (block_slope * (t_i - initial_last_point.ts)) /
                MULTIPLIER;
            epoch += 1;

            if (t_i == block.timestamp) {
                last_point.blk = block.number;
                break;
            } else {
                point_history[epoch] = last_point;
            }
        }

        if (addr != address(0)) {
            last_point.slope += (u_new.slope - u_old.slope);
            last_point.bias += (u_new.bias - u_old.bias);

            if (last_point.slope < 0) last_point.slope = 0;
            if (last_point.bias < 0) last_point.bias = 0;
        }

        // Record the changed point into history
        point_history[epoch] = last_point;

        if (addr != address(0)) {
            // Schedule the slope changes (slope is going down)
            // We subtract new_user_slope from [new_locked.end]
            // and add old_user_slope to [old_locked.end]
            if (old_locked.end > block.timestamp) {
                // old_dslope was <something> - u_old.slope, so we cancel that
                old_dslope += u_old.slope;

                if (new_locked.end == old_locked.end) old_dslope -= u_new.slope; // It was a new deposit, not extension

                slope_changes[old_locked.end] = old_dslope;
            }

            if (new_locked.end > block.timestamp) {
                if (new_locked.end > old_locked.end) {
                    new_dslope -= u_new.slope; // old slope disappeared at this point
                    slope_changes[new_locked.end] = new_dslope;
                }
            }

            // Now handle user history
            uint256 user_epoch = user_point_epoch[addr] + 1;

            user_point_epoch[addr] = user_epoch;
            u_new.ts = block.timestamp;
            u_new.blk = block.number;
            user_point_history[addr][user_epoch] = u_new;
        }
    }

    function _depositFor(
        address _addr,
        uint256 _value,
        uint256 unlock_time,
        LockedBalance storage _locked,
        DepositTypes depositTypes
    ) internal {
        uint256 supply_before = _totalSupply;

        _totalSupply = supply_before + _value;
        LockedBalance memory old_locked = _locked;

        _locked.amount += _value;

        if (unlock_time != 0) {
            _locked.end = unlock_time;
        }

        for (uint256 i = 0; i < reward_pools.length; i++) {
            reward_pools[i].stake(_addr);
        }

        _checkpoint(_addr, old_locked, _locked);

        if (_value != 0) {
            IERC20(token).safeTransferFrom(_addr, address(this), _value);
        }

        emit Deposit(_addr, _value, _locked.end, depositTypes, block.timestamp);
        emit Supply(supply_before, supply_before + _value);
    }

    function depositFor(address _addr, uint256 _value) external nonReentrant {
        LockedBalance storage _locked = locked[_addr];

        require(_value > 0, "need non-zero value");
        require(_locked.amount > 0, "no existing lock found");
        require(
            _locked.end > block.timestamp,
            "cannot add to expired lock. Withdraw"
        );

        _depositFor(
            _addr,
            _value,
            0,
            _locked,
            DepositTypes.DEPOSIT_FOR_TYPE
        );
    }

    function createLock(uint256 _value, uint256 _unlock_time)
        external
        nonReentrant
    {
        uint256 unlock_time = (_unlock_time / WEEK) * WEEK;
        LockedBalance storage _locked = locked[msg.sender];

        require(_value > 0, "need non-zero value");
        require(_locked.amount == 0, "Withdraw old tokens first");
        require(
            unlock_time > block.timestamp,
            "can only lock until time in the future"
        );
        require(
            unlock_time <= block.timestamp + MAXTIME,
            "voting lock can be 4 years max"
        );

        _depositFor(
            msg.sender,
            _value,
            unlock_time,
            _locked,
            DepositTypes.CREATE_LOCK_TYPE
        );
    }

    function increaseAmount(uint256 _value) external nonReentrant {
        LockedBalance storage _locked = locked[msg.sender];
        require(_value > 0, "need non-zero value");
        require(_locked.amount > 0, "No existing lock found");
        require(
            _locked.end > block.timestamp,
            "Cannot add to expired lock. Withdraw"
        );

        _depositFor(
            msg.sender,
            _value,
            0,
            _locked,
            DepositTypes.INCREASE_LOCK_AMOUNT
        );
    }

    function increaseUnlockTime(uint256 _unlock_time) external nonReentrant {
        LockedBalance storage _locked = locked[msg.sender];
        uint256 unlock_time = (_unlock_time / WEEK) * WEEK;

        require(_locked.end > block.timestamp, "Lock expired");
        require(_locked.amount > 0, "Nothing is locked");
        require(unlock_time > _locked.end, "Can only increase lock duration");
        require(
            unlock_time <= block.timestamp + MAXTIME,
            "Voting lock can be 4 years max"
        );

        _depositFor(
            msg.sender,
            0,
            unlock_time,
            _locked,
            DepositTypes.INCREASE_UNLOCK_TIME
        );
    }

    function withdraw() public nonReentrant {
        LockedBalance storage _locked = locked[msg.sender];

        require(block.timestamp >= _locked.end, "The lock didn't expire");
        uint256 locked_amount = _locked.amount;

        LockedBalance memory old_locked = _locked;

        _locked.end = 0;
        _locked.amount = 0;

        uint256 supply_before = _totalSupply;

        _totalSupply = supply_before - locked_amount;

        _checkpoint(msg.sender, old_locked, _locked);

        IERC20(token).safeTransfer(msg.sender, locked_amount);

        for (uint256 i = 0; i < reward_pools.length; i++) {
            reward_pools[i].withdraw(msg.sender);
        }

        emit Withdraw(msg.sender, locked_amount, block.timestamp);
        emit Supply(supply_before, supply_before - locked_amount);
    }

    function findBlockEpoch(uint256 _block, uint256 max_epoch)
        internal
        view
        returns (uint256)
    {
        uint256 _min = 0;
        uint256 _max = max_epoch;

        for (uint256 i = 0; i < 128; i++) {
            if (_min >= _max) {
                break;
            }

            uint256 _mid = (_min + _max + 1) / 2;

            if (point_history[_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }

        return _min;
    }

    function balanceOf(address addr, uint256 _t) public view returns (uint256) {
        if (_t == 0) {
            _t = block.timestamp;
        }

        uint256 _epoch = user_point_epoch[addr];

        if (_epoch == 0) {
            return 0;
        } else {
            Point memory last_point = user_point_history[addr][_epoch];

            require(_t >= last_point.ts, "!_t");

            last_point.bias -= last_point.slope * (_t - last_point.ts);

            if (last_point.bias < 0) {
                last_point.bias = 0;
            }

            return last_point.bias;
        }
    }

    function balanceOf(address account) public view returns (uint256) {
        return balanceOf(account, block.timestamp);
    }

    function balanceOfAt(address addr, uint256 _block)
        public
        view
        returns (uint256)
    {
        require(_block <= block.number);

        uint256 _min = 0;
        uint256 _max = user_point_epoch[addr];

        for (uint256 i = 0; i < 128; i++) {
            if (_min >= _max) {
                break;
            }

            uint256 _mid = (_min + _max + 1) / 2;

            if (user_point_history[addr][_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }

        Point memory upoint = user_point_history[addr][_min];

        uint256 current_point = findBlockEpoch(_block, epoch);
        Point memory point_0 = point_history[current_point];
        uint256 d_block = 0;
        uint256 d_t = 0;

        if (current_point < epoch) {
            Point memory point_1 = point_history[current_point + 1];
            d_block = point_1.blk - point_0.blk;
            d_t = point_1.ts - point_0.ts;
        } else {
            d_block = block.number - point_0.blk;
            d_t = block.timestamp - point_0.ts;
        }

        uint256 block_time = point_0.ts;

        if (d_block != 0) {
            block_time += (d_t * (_block - point_0.blk)) / d_block;
        }

        upoint.bias -= upoint.slope * (block_time - upoint.ts);

        if (upoint.bias >= 0) {
            return upoint.bias;
        } else {
            return 0;
        }
    }

    function supplyAt(Point memory point, uint256 t)
        internal
        view
        returns (uint256)
    {
        uint256 t_i = (point.ts / WEEK) * WEEK;

        for (uint256 i = 0; i < 255; i++) {
            t_i += WEEK;
            uint256 d_slope = 0;

            if (t_i > t) {
                t_i = t;
            } else {
                d_slope = slope_changes[t_i];
            }

            require(t_i >= point.ts, "!t_i");

            point.bias -= point.slope * (t_i - point.ts);

            if (t_i == t) break;

            point.slope += d_slope;
            point.ts = t_i;
        }

        if (point.bias < 0) {
            point.bias = 0;
        }

        return point.bias;
    }

    function totalSupply(uint256 t) public view returns (uint256) {
        if (t == 0) {
            t = block.timestamp;
        }

        Point memory last_point = point_history[epoch];

        return supplyAt(last_point, t);
    }

    function totalSupplyAt(uint256 _block) public view returns (uint256) {
        require(_block <= block.number);

        uint256 target_epoch = findBlockEpoch(_block, epoch);

        Point memory point = point_history[target_epoch];
        uint256 dt = 0;

        if (target_epoch < epoch) {
            Point memory point_next = point_history[target_epoch + 1];

            if (point.blk != point_next.blk) {
                dt =
                    ((_block - point.blk) * (point_next.ts - point.ts)) /
                    (point_next.blk - point.blk);
            }
        } else {
            if (point.blk != block.number) {
                dt =
                    ((_block - point.blk) * (block.timestamp - point.ts)) /
                    (block.number - point.blk);
            }
        }

        return supplyAt(point, point.ts + dt);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
}
