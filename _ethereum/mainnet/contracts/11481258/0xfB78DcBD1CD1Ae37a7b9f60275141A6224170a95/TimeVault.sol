//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./IXVIX.sol";

contract TimeVault is ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public constant WITHDRAWAL_DELAY = 7 days;
    uint256 public constant WITHDRAWAL_WINDOW = 48 hours;

    address public token;
    mapping (address => uint256) public balances;
    mapping (address => uint256) public withdrawalTimestamps;
    mapping (address => uint256) public withdrawalAmounts;
    mapping (uint256 => uint256) public withdrawalSlots;

    event Deposit(address account, uint256 amount);
    event BeginWithdrawal(address account, uint256 amount);
    event Withdraw(address account, uint256 amount);

    constructor(address _token) public {
        token = _token;
    }

    function deposit(uint256 _amount) public nonReentrant {
        require(_amount > 0, "TimeVault: insufficient amount");
        address account = msg.sender;
        IERC20(token).transferFrom(account, address(this), _amount);
        balances[account] = balances[account].add(_amount);
        emit Deposit(account, _amount);
    }

    function beginWithdrawal(uint256 _amount) public nonReentrant {
        address account = msg.sender;
        require(_amount > 0, "TimeVault: insufficient amount");
        require(_amount <= balanceOf(account), "TimeVault: insufficient balance");

        _decreaseWithdrawalSlot(withdrawalTimestamps[account], withdrawalAmounts[account]);

        uint256 time = block.timestamp.add(WITHDRAWAL_DELAY);
        withdrawalTimestamps[account] = time;
        withdrawalAmounts[account] = _amount;

        _increaseWithdrawalSlot(time, _amount);
        emit BeginWithdrawal(account, _amount);
    }

    function withdraw(address _receiver) public nonReentrant {
        address account = msg.sender;
        uint256 currentTime = block.timestamp;
        uint256 minTime = withdrawalTimestamps[account];
        require(minTime != 0, "TimeVault: withdrawal not initiated");
        require(currentTime > minTime, "TimeVault: withdrawal timing not reached");

        uint256 maxTime = minTime.add(WITHDRAWAL_WINDOW);
        require(currentTime < maxTime, "TimeVault: withdrawal window already passed");

        uint256 amount = withdrawalAmounts[account];
        require(amount <= balanceOf(account), "TimeVault: insufficient amount");

        _decreaseWithdrawalSlot(minTime, amount);

        withdrawalTimestamps[account] = 0;
        withdrawalAmounts[account] = 0;

        balances[account] = balances[account].sub(amount);

        IXVIX(token).rebase();
        IERC20(token).transfer(_receiver, amount);

        emit Withdraw(account, amount);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function getWithdrawalSlot(uint256 _time) public pure returns (uint256) {
        return _time.div(WITHDRAWAL_WINDOW);
    }

    function _increaseWithdrawalSlot(uint256 _time, uint256 _amount) private {
        uint256 slot = getWithdrawalSlot(_time);
        withdrawalSlots[slot] = withdrawalSlots[slot].add(_amount);
    }

    function _decreaseWithdrawalSlot(uint256 _time, uint256 _amount) private {
        if (_time == 0 || _amount == 0) { return; }
        uint256 slot = getWithdrawalSlot(_time);
        if (_amount > withdrawalSlots[slot]) {
            withdrawalSlots[slot] = 0;
            return;
        }
        withdrawalSlots[slot] = withdrawalSlots[slot].sub(_amount);
    }
}
