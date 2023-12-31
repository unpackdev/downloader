// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Math.sol";

import "./IVeBend.sol";
import "./IWETH.sol";
import "./ILendPool.sol";
import "./IFeeDistributor.sol";
import "./ILendPoolAddressesProvider.sol";

contract FeeDistributor is
    IFeeDistributor,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    uint256 public constant WEEK = 7 * 86400;
    uint256 public constant TOKEN_CHECKPOINT_DEADLINE = 86400;

    uint256 public startTime;
    uint256 public timeCursor;
    mapping(address => uint256) public timeCursorOf;
    mapping(address => uint256) public userEpochOf;

    uint256 public override lastDistributeTime;
    mapping(uint256 => uint256) public tokensPerWeek;
    uint256 public tokenLastBalance;

    mapping(uint256 => uint256) public veSupply; // VE total supply at week bounds

    mapping(address => uint256) public totalClaimed;

    IVeBend public veBEND;
    IWETH public WETH;
    ILendPoolAddressesProvider public override addressesProvider;

    // deprecated
    address public token;

    // deprecated
    address public override bendCollector;

    uint256 public totalDistributedBalance;

    function initialize(
        IWETH _weth,
        address _tokenAddress,
        IVeBend _veBendAddress,
        ILendPoolAddressesProvider _addressesProvider,
        address _bendCollector
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        addressesProvider = _addressesProvider;
        veBEND = _veBendAddress;
        WETH = _weth;
        bendCollector = _bendCollector;
        token = _tokenAddress;

        uint256 t = (block.timestamp / WEEK) * WEEK;
        startTime = t;
        lastDistributeTime = t;
        timeCursor = t;
    }

    /***
     *@notice Update fee checkpoint
     *@dev Up to 52 weeks since the last update
     */
    function _checkpointDistribute() internal {
        uint256 tokenBalance = WETH.balanceOf(address(this));

        uint256 toDistribute = tokenBalance - tokenLastBalance;
        totalDistributedBalance += toDistribute;

        tokenLastBalance = tokenBalance;
        uint256 t = lastDistributeTime;
        uint256 sinceLast = block.timestamp - t;
        lastDistributeTime = block.timestamp;

        uint256 thisWeek = (t / WEEK) * WEEK;
        uint256 nextWeek = 0;
        for (uint256 i = 0; i < 52; i++) {
            nextWeek = thisWeek + WEEK;
            if (block.timestamp < nextWeek) {
                if (sinceLast == 0 && block.timestamp == t) {
                    tokensPerWeek[thisWeek] += toDistribute;
                } else {
                    tokensPerWeek[thisWeek] +=
                        (toDistribute * (block.timestamp - t)) /
                        sinceLast;
                }
                break;
            } else {
                if (sinceLast == 0 && nextWeek == t) {
                    tokensPerWeek[thisWeek] += toDistribute;
                } else {
                    tokensPerWeek[thisWeek] +=
                        (toDistribute * (nextWeek - t)) /
                        sinceLast;
                }
            }
            t = nextWeek;
            thisWeek = nextWeek;
        }

        emit Distributed(block.timestamp, toDistribute);
    }

    /***
     *@notice Transfer fee and update checkpoint
     *@dev Manual transfer and update in extreme cases, The checkpoint can be updated at most once every 24 hours
     */

    function distribute() external override {
        _checkpointTotalSupply();
        _distribute();
    }

    function _distribute() internal {
        _checkpointDistribute();
    }

    function checkpointTotalSupply() external {
        _checkpointTotalSupply();
    }

    /***
    *@notice Update the veBEND total supply checkpoint
    *@dev The checkpoint is also updated by the first claimant each
         new epoch week. This function may be called independently
         of a claim, to reduce claiming gas costs.
    */
    function _checkpointTotalSupply() internal {
        uint256 t = timeCursor;
        uint256 roundedTimestamp = (block.timestamp / WEEK) * WEEK;
        veBEND.checkpointSupply();

        for (uint256 i = 0; i < 52; i++) {
            if (t > roundedTimestamp) {
                break;
            } else {
                uint256 epoch = _findTimestampEpoch(t);
                IVeBend.Point memory pt = veBEND.getSupplyPointHistory(epoch);
                int256 dt = 0;
                if (t > pt.ts) {
                    // If the point is at 0 epoch, it can actually be earlier than the first deposit
                    // Then make dt 0
                    dt = int256(t - pt.ts);
                }
                int256 _veSupply = pt.bias - pt.slope * dt;
                veSupply[t] = 0;
                if (_veSupply > 0) {
                    veSupply[t] = uint256(_veSupply);
                }
            }
            t += WEEK;
        }

        timeCursor = t;
    }

    function _findTimestampEpoch(
        uint256 _timestamp
    ) internal view returns (uint256) {
        uint256 _min = 0;
        uint256 _max = veBEND.epoch();
        for (uint256 i = 0; i < 128; i++) {
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 2) / 2;
            IVeBend.Point memory pt = veBEND.getSupplyPointHistory(_mid);
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
            IVeBend.Point memory pt = veBEND.getUserPointHistory(_user, _mid);
            if (pt.ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    struct Claimable {
        uint256 amount;
        uint256 userEpoch;
        uint256 maxUserEpoch;
        uint256 weekCursor;
    }

    function _claimable(
        address _addr,
        uint256 _lastDistributeTime
    ) internal view returns (Claimable memory) {
        uint256 roundedTimestamp = (_lastDistributeTime / WEEK) * WEEK;
        uint256 userEpoch = 0;
        uint256 toDistribute = 0;

        uint256 maxUserEpoch = veBEND.getUserPointEpoch(_addr);
        if (maxUserEpoch == 0) {
            // No lock = no fees
            return Claimable(0, 0, 0, 0);
        }
        uint256 weekCursor = timeCursorOf[_addr];
        if (weekCursor == 0) {
            // Need to do the initial binary search
            userEpoch = _findTimestampUserEpoch(_addr, startTime, maxUserEpoch);
        } else {
            userEpoch = userEpochOf[_addr];
        }

        if (userEpoch == 0) {
            userEpoch = 1;
        }

        IVeBend.Point memory userPoint = veBEND.getUserPointHistory(
            _addr,
            userEpoch
        );

        if (weekCursor == 0) {
            weekCursor = ((userPoint.ts + WEEK - 1) / WEEK) * WEEK;
        }

        if (weekCursor >= roundedTimestamp) {
            return Claimable(0, userEpoch, maxUserEpoch, weekCursor);
        }

        if (weekCursor < startTime) {
            weekCursor = startTime;
        }
        IVeBend.Point memory oldUserPoint;

        // Iterate over weeks
        for (uint256 i = 0; i < 255; i++) {
            if (weekCursor >= roundedTimestamp) {
                break;
            }
            if (weekCursor >= userPoint.ts && userEpoch <= maxUserEpoch) {
                userEpoch += 1;
                oldUserPoint = userPoint;
                if (userEpoch > maxUserEpoch) {
                    IVeBend.Point memory emptyPoint;
                    userPoint = emptyPoint;
                } else {
                    userPoint = veBEND.getUserPointHistory(_addr, userEpoch);
                }
            } else {
                // Calc
                // + i * 2 is for rounding errors
                int256 dt = int256(weekCursor - oldUserPoint.ts);
                int256 _balanceOf = oldUserPoint.bias - dt * oldUserPoint.slope;
                uint256 balanceOf = 0;
                if (_balanceOf > 0) {
                    balanceOf = uint256(_balanceOf);
                }
                if (balanceOf == 0 && userEpoch > maxUserEpoch) {
                    break;
                }
                uint256 _veSupply = veSupply[weekCursor];
                if (balanceOf > 0 && _veSupply > 0) {
                    toDistribute +=
                        (balanceOf * tokensPerWeek[weekCursor]) /
                        _veSupply;
                }

                weekCursor += WEEK;
            }
        }

        userEpoch = Math.min(maxUserEpoch, userEpoch - 1);
        return Claimable(toDistribute, userEpoch, maxUserEpoch, weekCursor);
    }

    function claimable(address _addr) external view override returns (uint256) {
        return _claimable(_addr, lastDistributeTime).amount;
    }

    /***
     *@notice Claim fees for `_addr`
     *@dev Each call to claim look at a maximum of 50 user veBEND points.
        For accounts with many veBEND related actions, this function
        may need to be called more than once to claim all available
        fees. In the `Claimed` event that fires, if `claimEpoch` is
        less than `maxEpoch`, the account may claim again.
     *@param weth Whether claim weth or raw eth
     *@return uint256 Amount of fees claimed in the call
     */
    function claim(bool weth) external override nonReentrant returns (uint256) {
        address _sender = msg.sender;

        // update veBEND total supply checkpoint when a new epoch start
        if (block.timestamp >= timeCursor) {
            _checkpointTotalSupply();
        }

        // Transfer fee and update checkpoint
        if (block.timestamp > lastDistributeTime + TOKEN_CHECKPOINT_DEADLINE) {
            _distribute();
        }

        Claimable memory _st_claimable = _claimable(
            _sender,
            lastDistributeTime
        );

        uint256 amount = _st_claimable.amount;
        userEpochOf[_sender] = _st_claimable.userEpoch;
        timeCursorOf[_sender] = _st_claimable.weekCursor;

        if (amount != 0) {
            tokenLastBalance -= amount;
            if (weth) {
                WETH.transfer(_sender, amount);
            } else {
                WETH.withdraw(amount);
                _safeTransferETH(_sender, amount);
            }
            totalClaimed[_sender] += amount;
            emit Claimed(
                _sender,
                amount,
                _st_claimable.userEpoch,
                _st_claimable.maxUserEpoch
            );
        }

        return amount;
    }

    function setTotalDistributedBalance(uint256 totalDistributed_)
        external
        onlyOwner
    {
        totalDistributedBalance = totalDistributed_;
    }

    function getTotalDistributedBalance() external view returns (uint256) {
        return totalDistributedBalance;
    }

    /**
     * @dev query distributed balance between weeks.
     * @param startWeekTime the start timestamp of the week (inclusive)
     * @param endWeekTime the end timestamp of the week (exclusive)
     * @notice All timestamp should be aligned to week and based on blockchain (UTC+0 timezone)
     */
    function getWeekDistributedBalance(
        uint256 startWeekTime,
        uint256 endWeekTime
    ) external view returns (uint256) {
        uint256 startWeek = (startWeekTime / WEEK) * WEEK;
        uint256 endWeek = (endWeekTime / WEEK) * WEEK;
        uint256 weekDistributedBalance = 0;
        for (
            uint256 nextWeek = startWeek;
            nextWeek < endWeek;
            nextWeek += WEEK
        ) {
            weekDistributedBalance += tokensPerWeek[nextWeek];
        }
        return weekDistributedBalance;
    }

    /**
     * @dev transfer ETH to an address, revert if it fails.
     * @param to recipient of the transfer
     * @param value the amount to send
     */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ETH_TRANSFER_FAILED");
    }

    /**
     * @dev Only WETH contract is allowed to transfer ETH here. Prevent other addresses to send Ether to this contract.
     */
    receive() external payable {
        require(msg.sender == address(WETH), "Receive not allowed");
    }
}
