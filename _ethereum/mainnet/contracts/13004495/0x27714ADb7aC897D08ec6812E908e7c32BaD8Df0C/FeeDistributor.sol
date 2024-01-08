// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.1;
pragma experimental ABIEncoderV2;

import "./console.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

interface Pointable {
    struct Point {
        int128 bias;
        int128 slope;
        uint256 ts;
        uint256 blk;
        uint256 iq_amt;
    }
}

interface IhiIQ is Pointable {
    function user_point_epoch(address addr) external view returns (uint256);

    function epoch() external view returns (uint256);

    function user_point_history(address addr, uint256 loc) external view returns (Point memory);

    function point_history(uint256 loc) external view returns (Point memory);

    function checkpoint() external;
}

contract FeeDistributor is Pointable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    /* ========== EVENTS ========== */

    event ToggleAllowCheckpointToken(bool toggleFlag);
    event TogglePause(bool toggleFlag);
    event CheckpointToken(uint256 time, uint256 tokens);
    event RecoveredERC20(address token, uint256 amount);
    event Claimed(address indexed recipient, uint256 amount, uint256 claimEpoch, uint256 maxEpoch);

    /* ========== STATE VARIABLES ========== */

    // Instances
    IhiIQ private hiIQ;
    IERC20 public token;

    // Constants
    uint256 private constant WEEK = 7 * 86400;
    uint256 private constant TOKEN_CHECKPOINT_DEADLINE = 86400;

    // Period related
    uint256 public startTime;
    uint256 public timeCursor;
    mapping(address => uint256) public timeCursorOf;
    mapping(address => uint256) public userEpochOf;

    uint256 public lastTokenTime;
    uint256[1000000000000000] public tokensPerWeek;

    uint256 public totalReceived;
    uint256 public tokenLastBalance;

    uint256[1000000000000000] public hiIQSupply;

    bool public canCheckPointToken;
    bool public paused = false;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _hiIQAddress,
        address _token,
        uint256 _startTime
    ) {
        uint256 t = (_startTime / WEEK) * WEEK;
        startTime = t;
        lastTokenTime = t;
        timeCursor = t;
        token = IERC20(_token);
        hiIQ = IhiIQ(_hiIQAddress);
    }

    /* ========== MATH ========== */

    function max(int128 a, int128 b) internal pure returns (int128) {
        return a >= b ? a : b;
    }

    function min(int128 a, int128 b) internal pure returns (int128) {
        return a < b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /* ========== VIEWS ========== */

    function hiIQForAt(address _user, uint256 _timestamp) external view returns (uint256) {
        uint256 maxUserEpoch = hiIQ.user_point_epoch(_user);
        uint256 epoch = _findTimestampUserEpoch(_user, _timestamp, maxUserEpoch);
        Point memory pt = hiIQ.user_point_history(_user, epoch);
        return uint256(max(pt.bias - pt.slope * int128(_timestamp - pt.ts), 0));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function checkpointToken() external {
        require(!paused, "Contract is paused");
        require(
            msg.sender == owner() ||
                (canCheckPointToken && (block.timestamp > lastTokenTime + TOKEN_CHECKPOINT_DEADLINE)),
            "Can't checkpoint token!"
        );
        _checkPointToken();
    }

    function _checkPointToken() internal {
        uint256 tokenBalance = token.balanceOf(address(this));
        uint256 toDistribute = tokenBalance.sub(tokenLastBalance);
        tokenLastBalance = tokenBalance;
        uint256 t = lastTokenTime;
        uint256 sinceLast = block.timestamp.sub(t);
        lastTokenTime = block.timestamp;
        uint256 thisWeek = t.div(WEEK).mul(WEEK);
        uint256 nextWeek = 0;

        for (uint256 i = 0; i < 20; i++) {
            nextWeek = thisWeek.add(WEEK);
            if (block.timestamp < nextWeek) {
                if (sinceLast == 0 && block.timestamp == t) {
                    tokensPerWeek[thisWeek] += toDistribute;
                } else {
                    tokensPerWeek[thisWeek] += toDistribute.mul(block.timestamp.sub(t)).div(sinceLast);
                }
                break;
            } else {
                if (sinceLast == 0 && nextWeek == t) {
                    tokensPerWeek[thisWeek] += toDistribute;
                } else {
                    tokensPerWeek[thisWeek] += toDistribute.mul(nextWeek.sub(t)).div(sinceLast);
                }
            }
            t = nextWeek;
            thisWeek = nextWeek;
        }
        emit CheckpointToken(block.timestamp, toDistribute);
    }

    function _findTimestampEpoch(uint256 _timestamp) internal view returns (uint256) {
        uint256 _min = 0;
        uint256 _max = hiIQ.epoch();
        for (uint256 i = 0; i < 128; i++) {
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 2) / 2;
            Point memory pt = hiIQ.point_history(_mid);
            if (pt.ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    function _findTimestampUserEpoch(
        address _user,
        uint256 _timestamp,
        uint256 _maxUserEpoch
    ) internal view returns (uint256) {
        uint256 _min = 0;
        uint256 _max = _maxUserEpoch;
        for (uint256 i = 0; i < 128; i++) {
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 2) / 2;
            Point memory pt = hiIQ.user_point_history(_user, _mid);
            if (pt.ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    function checkpointTotalSupply() external {
        require(!paused, "Contract is paused");
        _checkPointTotalSupply();
    }

    function _checkPointTotalSupply() internal {
        uint256 t = timeCursor;
        uint256 roundedTimestamp = block.timestamp.div(WEEK).mul(WEEK);
        hiIQ.checkpoint();

        for (uint256 i = 0; i < 20; i++) {
            if (t > roundedTimestamp) {
                break;
            } else {
                uint256 epoch = _findTimestampEpoch(t);
                Point memory pt = hiIQ.point_history(epoch);
                int128 dt = 0;
                if (t > pt.ts) {
                    dt = int128(t - pt.ts);
                }
                hiIQSupply[t] = uint256(max(pt.bias - pt.slope * dt, 0));
            }
            t += WEEK;
        }
        timeCursor = t;
    }

    function claim(address _addr) external nonReentrant returns (uint256) {
        require(!paused, "Contract is paused");
        if (block.timestamp >= timeCursor) {
            _checkPointTotalSupply();
        }

        uint256 _lastTokenTime = lastTokenTime;

        if (canCheckPointToken && (block.timestamp > _lastTokenTime + TOKEN_CHECKPOINT_DEADLINE)) {
            _checkPointToken();
            _lastTokenTime = block.timestamp;
        }

        _lastTokenTime = _lastTokenTime.div(WEEK).mul(WEEK);

        uint256 amount = _claim(_addr, _lastTokenTime);
        if (amount != 0) {
            tokenLastBalance -= amount;
            token.transfer(_addr, amount);
        }
        return amount;
    }

    function claimMany(address[] memory _receivers) external nonReentrant returns (bool) {
        require(!paused, "Contract is paused");
        if (block.timestamp >= timeCursor) {
            _checkPointTotalSupply();
        }

        uint256 _lastTokenTime = lastTokenTime;

        if (canCheckPointToken && (block.timestamp > _lastTokenTime + TOKEN_CHECKPOINT_DEADLINE)) {
            _checkPointToken();
            _lastTokenTime = block.timestamp;
        }

        _lastTokenTime = _lastTokenTime.div(WEEK).mul(WEEK);
        uint256 total = 0;

        for (uint256 i; i < _receivers.length; i++) {
            address _addr = _receivers[i];
            if (_addr == address(0)) {
                break;
            }

            uint256 amount = _claim(_addr, _lastTokenTime);
            if (amount != 0) {
                token.transfer(_addr, amount);
                total += amount;
            }
        }

        if (total != 0) {
            tokenLastBalance -= total;
        }

        return true;
    }

    function _claim(address _addr, uint256 _lastTokenTime) internal returns (uint256) {
        uint256 userEpoch = 0;
        uint256 toDistribute = 0;
        uint256 maxUserEpoch = hiIQ.user_point_epoch(_addr);
        uint256 _startTime = startTime;

        if (maxUserEpoch == 0) {
            return 0;
        }

        uint256 weekCursor = timeCursorOf[_addr];
        if (weekCursor == 0) {
            userEpoch = _findTimestampUserEpoch(_addr, _startTime, maxUserEpoch);
        } else {
            userEpoch = userEpochOf[_addr];
        }

        if (userEpoch == 0) {
            userEpoch = 1;
        }

        Point memory userPoint = hiIQ.user_point_history(_addr, userEpoch);

        if (weekCursor == 0) {
            weekCursor = (userPoint.ts + WEEK - 1).div(WEEK).mul(WEEK);
        }

        if (weekCursor >= _lastTokenTime) {
            return 0;
        }

        if (weekCursor < _startTime) {
            weekCursor = _startTime;
        }

        Point memory oldUserPoint;

        for (uint256 i = 0; i < 50; i++) {
            if (weekCursor >= _lastTokenTime) {
                break;
            }

            if (weekCursor >= userPoint.ts && userEpoch <= maxUserEpoch) {
                userEpoch += 1;
                oldUserPoint = userPoint;
                if (userEpoch > maxUserEpoch) {
                    Point memory emptyPoint;
                    userPoint = emptyPoint;
                } else {
                    userPoint = hiIQ.user_point_history(_addr, userEpoch);
                }
            } else {
                int128 dt = int128(weekCursor - oldUserPoint.ts);
                uint256 balanceOf = uint256(max(oldUserPoint.bias - dt * oldUserPoint.slope, 0));
                if (balanceOf == 0 && userEpoch > maxUserEpoch) {
                    break;
                }

                if (balanceOf > 0) {
                    toDistribute += balanceOf.mul(tokensPerWeek[weekCursor]).div(hiIQSupply[weekCursor]);
                }

                weekCursor += WEEK;
            }
        }

        userEpoch = min(maxUserEpoch, userEpoch - 1);
        userEpochOf[_addr] = userEpoch;
        timeCursorOf[_addr] = weekCursor;

        emit Claimed(_addr, toDistribute, userEpoch, maxUserEpoch);

        return toDistribute;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
        emit RecoveredERC20(tokenAddress, tokenAmount);
    }

    function toggleAllowCheckpointToken() external onlyOwner {
        bool flag = !canCheckPointToken;
        canCheckPointToken = flag;
        emit ToggleAllowCheckpointToken(flag);
    }

    function togglePause() external onlyOwner {
        bool flag = !paused;
        paused = flag;
        emit TogglePause(flag);
    }
}
