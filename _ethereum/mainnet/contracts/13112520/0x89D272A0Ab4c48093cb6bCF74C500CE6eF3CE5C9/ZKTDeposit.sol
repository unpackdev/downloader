// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Initializable.sol";
import "./Ownable.sol";
import "./Testable.sol";

contract ZKTDeposit is Ownable, Initializable, Testable {
    using SafeERC20 for IERC20;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event UpdateLockTime(address indexed owner, uint lockTime);

    struct DepositAmount {
        uint value;
        uint startDay;
    }

    uint public constant ONE_DAY = 1 days;
    IERC20 public token;

    // lock days
    uint public lockTime;
    uint public totalDeposits;
    mapping(address => DepositAmount[]) public depositAmounts;

    uint private locked;

    modifier lock() {
        require(locked == 0, 'ZKTDeposit: LOCKED');
        locked = 1;
        _;
        locked = 0;
    }

    constructor (address token_, address timer_) Testable(timer_){
        lockTime = 365;
        token = IERC20(token_);
    }

    function initialize(address token_, address timer_, address owner_) external initializer {
        lockTime = 365;
        token = IERC20(token_);
        timerAddress = timer_;
        _initOwner(owner_);
    }

    function updateLockTime(uint lockTime_) external onlyOwner {
        lockTime = lockTime_;
        emit UpdateLockTime(msg.sender, lockTime_);
    }

    function deposit(uint amount) external lock {
        require(amount > 0, "ZKTDeposit: amount is zero");
        token.safeTransferFrom(msg.sender, address(this), amount);
        totalDeposits = totalDeposits + amount;
        _addDeposit(msg.sender, amount);
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint amount) external lock {
        require(amount > 0, "ZKTDeposit: amount is zero");
        require(amount <= _available(msg.sender, getCurrentTime() / ONE_DAY), "ZKTDeposit: available is not enough");
        // update
        totalDeposits = totalDeposits - amount;
        _subDeposit(msg.sender, amount);
        // transfer
        token.safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function available(address account) external view returns(uint){
        return _available(account, getCurrentTime() / ONE_DAY);
    }

    function balanceOf(address account) external view returns(uint){
        return _balanceOf(account);
    }

    /**
     * @dev available withdraw amount
     */
    function _available(address account, uint currentDay) internal view returns(uint){
        uint amount = 0;
        DepositAmount[] storage depositArr = depositAmounts[account];
        uint len = depositArr.length;
        for(uint i = 0; i < len; i++){
            if (depositArr[i].startDay + lockTime <= currentDay){
                amount = amount + depositArr[i].value;
            }
        }
        return amount;
    }

    /**
     * @dev zktdeposit amount
     */
    function _balanceOf(address account) internal view returns(uint){
        uint amount = 0;
        DepositAmount[] storage depositArr = depositAmounts[account];
        uint len = depositArr.length;
        for(uint i = 0; i < len; i++){
            amount = amount + depositArr[i].value;
        }
        return amount;
    }

    function _addDeposit(address account, uint amount) internal {
        uint currentDay = getCurrentTime() / ONE_DAY;
        DepositAmount[] storage depositArr = depositAmounts[account];
        uint len = depositArr.length;
        if (len == 0){
            depositArr.push(DepositAmount({value: amount, startDay: currentDay}));
        } else {
            bool isExist = false;
            uint i = len - 1;
            while(i >= 0){
                if (depositArr[i].startDay == currentDay){
                    depositArr[i].value = depositArr[i].value + amount;
                    isExist = true;
                    break;
                }
                if (i == 0){
                    break;
                } else {
                    i = i - 1;
                }
            }
            if (!isExist){
                depositArr.push(DepositAmount({value: amount, startDay: currentDay}));
            }
        }
    }

    function _subDeposit(address account, uint amount) internal {
        uint currentDay = getCurrentTime() / ONE_DAY;
        DepositAmount[] storage depositArr = depositAmounts[account];
        uint len = depositArr.length;
        uint i = 0;
        uint tmp = 0;
        while (i < len){
            if (depositArr[i].startDay + lockTime <= currentDay){
                tmp = tmp + depositArr[i].value;
                if (tmp > amount) {
                    //add excess
                    depositArr[i].value = tmp - amount;
                    break;
                } else {
                    depositArr[i].value = depositArr[len - 1].value;
                    depositArr[i].startDay = depositArr[len - 1].startDay;
                    depositArr.pop();
                    len = len - 1;
                    if (tmp == amount){
                        break;
                    }
                }
            } else {
                i = i + 1;
            }
        }
    }
}