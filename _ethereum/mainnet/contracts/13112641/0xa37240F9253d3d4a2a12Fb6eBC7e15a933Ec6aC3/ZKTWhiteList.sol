// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Initializable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Testable.sol";

contract ZKTWhiteList is Ownable, Pausable, Initializable, Testable {
    using SafeERC20 for IERC20;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    struct DepositAmount {
        uint value;
        uint released;
        uint startDay;
    }

    IERC20 public zktToken;
    IERC20 public zktrToken;
    uint public constant ONE_DAY = 1 days;

    // The sum of all users
    uint public totalDeposits;
    uint public totalWithdrawals;

    // A single user
    mapping(address => uint) public deposits;
    mapping(address => uint) public withdrawals;
    mapping(address => DepositAmount[]) public depositAmounts;

    uint private locked;
    modifier lock() {
        require(locked == 0, 'ZKTWhiteList: LOCKED');
        locked = 1;
        _;
        locked = 0;
    }

    constructor (address zktToken_, address zktrToken_, address timerAddress_) Testable(timerAddress_){
        zktToken = IERC20(zktToken_);
        zktrToken = IERC20(zktrToken_);
    }

    function initialize(address zktToken_, address zktrToken_, address timerAddress_, address owner_) external initializer {
        zktToken = IERC20(zktToken_);
        zktrToken = IERC20(zktrToken_);
        timerAddress = timerAddress_;
        _initOwner(owner_);
    }

    function deposit(uint amount) external whenNotPaused lock {
        require(amount > 0, "ZKTWhiteList: amount is zero");
        zktrToken.safeTransferFrom(msg.sender, address(this), amount);
        _addDeposit(msg.sender, amount);
        deposits[msg.sender] = deposits[msg.sender] + amount;
        totalDeposits = totalDeposits + amount;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint amount) external lock {
        require(amount > 0, "ZKTWhiteList: amount is zero");
        require(amount <= _available(msg.sender, getCurrentTime() / ONE_DAY), "ZKTWhiteList: available is not enough");
        // update
        _addReleased(msg.sender, amount);
        withdrawals[msg.sender] = withdrawals[msg.sender] + amount;
        totalWithdrawals = totalWithdrawals + amount;
        // transfer
        zktToken.safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function available(address account) external view returns(uint){
        return _available(account, getCurrentTime() / ONE_DAY);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev available withdraw amount
     */
    function _available(address account, uint currentDay) internal view returns(uint){
        uint amount = 0;
        DepositAmount[] storage depositArr = depositAmounts[account];
        uint len = depositArr.length;
        for(uint i = 0; i < len; i++){
            amount = amount + _calcReleasable(depositArr[i].value, depositArr[i].released, depositArr[i].startDay, currentDay);
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
        } else if (currentDay <= startDay + 56){ // 8 weeks
            uint everyWeek = total / 100;
            return everyWeek * ((currentDay-startDay) / 7) - released;
        } else if (currentDay <= startDay + 356){ // 1 year
            uint everyMonth = total * 2 / 100;
            return (total * 8 / 100) + everyMonth * ((currentDay-startDay-56) / 30) - released;
        } else if (currentDay <= startDay + 1076){ // 2-3 years
            uint everyMonth = total * 3 / 100;
            return (total * 28 / 100) +  everyMonth * ((currentDay-startDay-356) / 30) - released;
        } else { // more than three years
            return total - released;
        }
    }

    function _addDeposit(address account, uint amount) internal {
        uint currentDay = getCurrentTime() / ONE_DAY;
        DepositAmount[] storage depositArr = depositAmounts[account];
        uint len = depositArr.length;
        if (len == 0){
            depositArr.push(DepositAmount({value: amount, released: 0, startDay: currentDay}));
        } else {
            bool isExist = false;
            for(uint i=len-1; i>=0; i--){
                if (depositArr[i].startDay == currentDay){
                    depositArr[i].value = depositArr[i].value + amount;
                    isExist = true;
                    break;
                }
                if (i == 0){
                    break;
                }
            }
            if (!isExist){
                depositArr.push(DepositAmount({value: amount, released: 0, startDay: currentDay}));
            }
        }
    }

    function _addReleased(address account, uint amount) internal {
        uint currentDay = getCurrentTime() / ONE_DAY;
        DepositAmount[] storage depositArr = depositAmounts[account];
        uint i = 0;
        uint tmp = 0;
        uint len = depositArr.length;
        while (i < len){
            uint avail = _calcReleasable(depositArr[i].value, depositArr[i].released, depositArr[i].startDay, currentDay);
            if (avail <= 0) {
                i = i + 1;
            } else {
                tmp = tmp + avail;
                if (tmp > amount){
                    depositArr[i].released = depositArr[i].released + (avail - (tmp - amount));
                    break;
                } else {
                    depositArr[i].released = depositArr[i].released + avail;
                    if (depositArr[i].value <= depositArr[i].released){
                        depositArr[i].value = depositArr[len - 1].value;
                        depositArr[i].released = depositArr[len - 1].released;
                        depositArr[i].startDay = depositArr[len - 1].startDay;
                        depositArr.pop();
                        len = len - 1;
                    } else {
                        i = i + 1;
                    }
                    if (tmp == amount) {
                        break;
                    }
                }
            }
        }
    }
}