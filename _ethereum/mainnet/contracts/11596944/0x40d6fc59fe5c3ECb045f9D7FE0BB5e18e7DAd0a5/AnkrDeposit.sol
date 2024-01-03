// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.11;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Lockable.sol";
import "./IAETH.sol";
import "./IMarketPlace.sol";
import "./Configurable.sol";

contract AnkrDeposit is OwnableUpgradeSafe, Lockable, Configurable {
    using SafeMath for uint256;

    event Deposit(
        address indexed user,
        uint256 value
    );

    // if ends at value is zero,
    event Freeze(
        address indexed user,
        uint256 value,
        uint256 endsAt
    );

    event Unfreeze(
        address indexed user,
        uint256 value
    );

    event Withdraw(
        address indexed user,
        uint256 value
    );

    event Compensate(address indexed provider, uint256 ankrAmount, uint256 etherAmount);

    IAETH private _AETHContract;

    IMarketPlace _marketPlaceContract;

    IERC20 private _ankrContract;

    address private _globalPoolContract;

    address _governanceContract;

    address _operator;

    mapping (address => uint256[]) public _userLocks;

    bytes32 constant _deposit_ = "AnkrDeposit#Deposit";

    bytes32 constant _freeze_ = "AnkrDeposit#Freeze";
    bytes32 constant _unfreeze_ = "AnkrDeposit#Unfreeze";
    bytes32 constant _lockTotal_ = "AnkrDeposit#LockTotal";
    bytes32 constant _lockEndsAt_ = "AnkrDeposit#LockEndsAt";
    bytes32 constant _lockAmount_ = "AnkrDeposit#LockAmount";
    bytes32 constant _lockID_ = "AnkrDeposit#LockID";

    bytes32 constant _allowed_ = "AnkrDeposit#Allowed";


    function deposit_init(address ankrContract, address globalPoolContract, address aethContract) internal initializer {
        OwnableUpgradeSafe.__Ownable_init();

        _ankrContract = IERC20(ankrContract);
        _globalPoolContract = globalPoolContract;
        _AETHContract = IAETH(aethContract);
        allowAddressForFunction(globalPoolContract, _unfreeze_);
        allowAddressForFunction(globalPoolContract, _freeze_);
    }

    modifier onlyOperator() {
        require(msg.sender == owner() || msg.sender == _operator, "Ankr Deposit#onlyOperator: not allowed");
        _;
    }

    modifier addressAllowed(address addr, bytes32 topic) {
        require(getConfig(_allowed_ ^ topic, addr) > 0, "Ankr Deposit#addressAllowed: You are not allowed to run this function");
        _;
    }

    function deposit() public unlocked(msg.sender) returns (uint256) {
        return _claimAndDeposit(msg.sender);
    }

    function deposit(address user) public unlocked(user) returns (uint256) {
        return _claimAndDeposit(user);
    }
    /*
        This function used to deposit ankr with transferFrom
    */
    function _claimAndDeposit(address user) private returns (uint256) {
        address ths = address(this);
        uint256 allowance = _ankrContract.allowance(user, ths);

        if (allowance == 0) {
            return 0;
        }

        _ankrContract.transferFrom(user, ths, allowance);

        setConfig(_deposit_, user, depositsOf(user).add(allowance));

        cleanUserLocks(user);

        emit Deposit(user, allowance);

        return allowance;
    }

    function withdraw(uint256 amount) public unlocked(msg.sender) returns (bool) {
        address sender = msg.sender;
        uint256 available = availableDepositsOf(sender);

        require(available >= amount, "Ankr Deposit#withdraw: You dont have available deposit balance");

        setConfig(_deposit_, sender, depositsOf(sender).sub(amount));

        _transferToken(sender, amount);

        cleanUserLocks(sender);

        emit Withdraw(sender, amount);

        return true;
    }

    function _unfreeze(address addr, uint256 amount)
    internal
    returns (bool)
    {
        setConfig(_freeze_, addr, _frozenDeposits(addr).sub(amount, "Ankr Deposit#_unfreeze: Insufficient funds"));
        cleanUserLocks(addr);
        emit Unfreeze(addr, amount);
        return true;
    }

    function _freeze(address addr, uint256 amount)
    internal
    returns (bool)
    {
        _claimAndDeposit(addr);

        require(depositsOf(addr) >= amount, "Ankr Deposit#_freeze: You dont have enough amount to freeze ankr");
        setConfig(_freeze_, addr, _frozenDeposits(addr).add(amount));

        cleanUserLocks(addr);

        emit Freeze(addr, amount, 0);
        return true;
    }

    function unfreeze(address addr, uint256 amount)
    public
    addressAllowed(_globalPoolContract, _unfreeze_)
    returns (bool)
    {
        return _unfreeze(addr, amount);
    }

    function freeze(address addr, uint256 amount)
    public
    addressAllowed(_globalPoolContract, _freeze_)
    returns (bool)
    {
        return _freeze(addr, amount);
    }

    function availableDepositsOf(address user) public view returns (uint256) {
        return depositsOf(user).sub(frozenDepositsOf(user));
    }

    function depositsOf(address user) public view returns (uint256) {
        return getConfig(_deposit_, user);
    }

    function frozenDepositsOf(address user) public view returns (uint256) {
        return _frozenDeposits(user).add(lockedDepositsOf(user));
    }

    function _frozenDeposits(address user) internal view returns(uint256) {
        return getConfig(_freeze_, user);
    }

    function lockedDepositsOf(address user) public view returns(uint256) {
        return getConfig(_lockTotal_, user).sub(availableAmountForUnlock(user));
    }

    function _transferToken(address to, uint256 amount) internal {
        require(_ankrContract.transfer(to, amount), "Failed token transfer");
    }

    function allowAddressForFunction(address addr, bytes32 topic) public onlyOperator {
        setConfig(_allowed_ ^ topic, addr, 1);
    }

    function _addNewLockToUser(address user, uint256 amount, uint256 endsAt, uint256 lockId) internal {
        uint256 deposits = depositsOf(user);
        uint256 lockedDeposits = lockedDepositsOf(user);
        if (amount <= lockedDeposits) {
            return;
        }
        amount = amount.sub(lockedDeposits);
        require(amount <= deposits, "Ankr Deposit#_addNewLockToUser: Insufficient funds");

        require(getConfig(_lockEndsAt_, lockId) == 0, "Ankr Deposit#_addNewLockToUser: Cannot set same lock id");
        if (amount == 0) return;
        // set ends at property for lock
        setConfig(_lockEndsAt_, lockId, endsAt);
        // set amount property for lock
        setConfig(_lockAmount_, lockId, amount);
        setConfig(_lockTotal_, user, getConfig(_lockTotal_, user).add(amount));

        // set lock id
        _userLocks[user].push(lockId);
    }

    function cleanUserLocks(address user) public {
        uint256 userLockCount = _userLocks[user].length;
        uint256 currentTs = block.timestamp;

        if (userLockCount == 0) return;

        for (uint256 i = 0; i < userLockCount; i++) {
            uint256 lockId = _userLocks[user][i];
            if (getConfig(_lockEndsAt_, lockId) > currentTs && getConfig(_lockAmount_, lockId) != 0) {
                continue;
            }

            // set total lock amount for user
            setConfig(_lockTotal_, user, getConfig(_lockTotal_, user).sub(getConfig(_lockAmount_, lockId)));
            // remove lock from array
            _userLocks[user][i] = _userLocks[user][userLockCount.sub(1)];
            _userLocks[user].pop();
            //
            userLockCount--;
            i--;
        }
    }

    function availableAmountForUnlock(address user) public view returns (uint256) {
        uint256 userLockCount = _userLocks[user].length;
        uint256 amount = 0;
        if (userLockCount == 0) {
            return amount;
        }

        for (uint256 i = 0; i < userLockCount; i++) {
            uint256 lockId = _userLocks[user][i];
            if (getConfig(_lockEndsAt_, lockId) <= now) {
                amount += getConfig(_lockAmount_, lockId);
            }
        }

        return amount;
    }

    function changeOperator(address operator) public onlyOwner {
        _operator = operator;
    }
}
