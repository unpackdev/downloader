// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Initializable.sol";
import "./Ownable.sol";
import "./Testable.sol";

contract ZKTVesting is Ownable, Initializable, Testable {

    event BatchReward(address indexed from, uint totalAmount, string memo);

    event Reward(address indexed from, address indexed to, uint value, string memo);

    event Withdraw(address indexed from, address indexed to, uint value, string memo);

    event UpdateLockedPosition(address indexed from, uint lockedPosition);

    using SafeERC20 for IERC20;

    struct Vesting {
        uint total;
        uint released;
        uint startDay;
    }

    uint public constant DURATION = 200;
    uint public constant ONE_DAY = 1 days;

    mapping(address => uint) private avails;
    mapping(address => uint) public cumulativeWithdrawals;
    mapping(address => mapping(uint => Vesting)) public vestings;

    IERC20 public erc20Token;
    uint public lockedPosition;
    uint public totalRewards;

    uint private locked;
    modifier lock() {
        require(locked == 0, 'ZKTVesting: LOCKED');
        locked = 1;
        _;
        locked = 0;
    }

    constructor (address token_, address timer_) Testable(timer_){
        lockedPosition = 65;
        erc20Token = IERC20(token_);
    }

    function initialize(address token_, address timer_, address owner_) external initializer {
        lockedPosition = 65;
        erc20Token = IERC20(token_);
        timerAddress = timer_;
        _initOwner(owner_);
    }

    function updateLockedPosition(uint lockedPosition_) external onlyOwner {
        require(lockedPosition_ <= 100, "ZKTVesting: lockedPosition too big");
        lockedPosition = lockedPosition_;
        emit UpdateLockedPosition(msg.sender, lockedPosition_);
    }

    /**
     * @dev Reward multiple miners
     */
    function batchReward(address[] calldata tos, uint[] calldata amounts, string calldata memo) external onlyOwner {
        require(tos.length > 0, "batchReward: length is zero");
        require(tos.length == amounts.length, "batchReward: Unequal length");
        uint totalAmount = 0;
        for(uint i = 0; i < tos.length; i++) {
            _reward(tos[i], amounts[i], memo);
            totalAmount = totalAmount + amounts[i];
        }
        totalRewards = totalRewards + totalAmount;
        emit BatchReward(address(this), totalAmount, memo);
    }

    /**
     * @dev all available tokens will be withdraw
     */
    function withdraw() external lock() returns (bool) {
        address account = _msgSender();
        uint currentDay = getCurrentTime() / ONE_DAY;
        uint amount = avails[account];
        for(uint i = 0; i < DURATION; i++){
            Vesting storage vesting = vestings[account][i];
            if (vesting.total > 0){
                // calculate releasable
                uint releasable = _calcReleasable(vesting.total, vesting.released, vesting.startDay, currentDay);
                if (releasable > 0){
                    amount = amount + releasable;
                    uint tmpReleased = vesting.released + releasable;
                    if (vesting.total <= tmpReleased) {
                        // has release all
                        vesting.total = 0;
                        vesting.released = 0;
                        vesting.startDay = 0;
                    } else {
                        vesting.released = tmpReleased;
                    }
                }
            }
        }
        avails[account] = 0;
        // add released
        cumulativeWithdrawals[account] = cumulativeWithdrawals[account] + amount;
        // check
        require(amount > 0, "withdraw: amount is zero");
        // transfer
        erc20Token.safeTransfer(account, amount);
        // event
        emit Withdraw(address(this), account, amount, "Rewards for mint");
        return true;
    }

    /**
     * @dev The number of tokens available in the account
     */
    function available(address account) external view returns (uint) {
        uint amount = avails[account];
        uint currentDay = getCurrentTime() / ONE_DAY;
        for(uint i = 0; i < DURATION; i++){
            Vesting storage vesting = vestings[account][i];
            if (vesting.total > 0){
                amount = amount + _calcReleasable(vesting.total, vesting.released, vesting.startDay, currentDay);
            }
        }
        return amount;
    }

    /**
     * @dev Returns the remaining numbers are available and unavailable
     */
    function remain(address account) external view returns (uint) {
        uint amount = avails[account];
        for(uint i = 0; i < DURATION; i++){
            Vesting storage vesting = vestings[account][i];
            if (vesting.total > 0){
                amount = amount + (vesting.total - vesting.released);
            }
        }
        return amount;
    }

    /**
     * @dev Returns the current number of tokens that can be released
     */
    function _calcReleasable(uint total, uint released, uint startDay, uint currentDay) internal pure returns (uint){
        if (total <= released) {
            return 0;
        } else if (currentDay <= startDay) {
            return 0;
        } else {
            if (currentDay >= startDay + DURATION){
                return total - released;
            } else {
                return total * (currentDay-startDay) / DURATION - released;
            }
        }
    }

    /**
     * @dev Give a prize to a miner
     */
    function _reward(address to, uint amount, string calldata memo) internal {
        require(to != address(0), "_reward: zero address");
        if (amount > 0){
            // Direct release
            uint directRelease = amount * (100 - lockedPosition) / 100;
            // Linear release
            uint linearRelease = amount - directRelease;

            uint currentDay = getCurrentTime() / ONE_DAY;
            Vesting storage vesting = vestings[to][currentDay % DURATION];

            if (currentDay == vesting.startDay){
                // same day
                vesting.total = vesting.total + linearRelease;
                avails[to] = avails[to] + directRelease;
            }else{
                // before duration days, all release
                avails[to] = avails[to] + directRelease + (vesting.total - vesting.released);
                // update
                vesting.total = linearRelease;
                vesting.released = 0;
                vesting.startDay = currentDay;
            }
            emit Reward(msg.sender, to, amount, memo);
        }
    }
}