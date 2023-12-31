pragma solidity ^0.8.14;

import "./IERC20.sol";
import "./ITokenLocker.sol";

contract TokenLocker is ITokenLocker {
    address public immutable masterChef;
    mapping(address => mapping(address => LockedToken)) internal _userLockedToken;

    // This contract will be deployed thru create2 directly from the MasterChef contract
    constructor() {
        masterChef = msg.sender;
    }

    bool private _locked;
    modifier nonReentrant() {
        require(_locked == false, "TokenLocker: REENTRANT_CALL");
        _locked = true;
        _;
        _locked = false;
    }

    function lockToken(address _user, address _token, uint256 _amount, uint256 _duration) external nonReentrant {
        require(msg.sender == _userLockedToken[_user][_token].locker || (_userLockedToken[_user][_token].locker == address(0) && (msg.sender == _user || msg.sender == masterChef)), "TokenLocker: FORBIDDEN_WITHDRAW");
        require(IERC20(_token).balanceOf(msg.sender) >= _amount, "TokenLocker: AMOUNT_EXCEEDS_BALANCE");

        // If this token has already an amount locked by this caller, just increase its locking amount by _amount;
        // And increase its locking duration by _duration (if endTime is not met yet) or set it to "now" + _duration
        // (if endTime is already passed). Avoids exploiting of _duration to decrease the lock period.
        if (_userLockedToken[_user][_token].amount > 0) {
            if (_amount > 0) {
                _increaseLockedAmount(_user, _token, _amount);
            }
            if (_duration > 0) {
                _increaseLockDuration(_user, _token, _duration);
            }
            return;
        }

        if (_amount > 0) {
            _userLockedToken[_user][_token] = LockedToken({
                locker: msg.sender,
                endTime: block.timestamp + _duration,
                amount: _amount
            });

            IERC20(_token).transferFrom(msg.sender, address(this), _amount);

            emit TokenLocked(_user, _token, _amount, _duration);
        }
    }

    function _increaseLockedAmount(address _user, address _token, uint256 _amount) internal {
        _userLockedToken[_user][_token].amount += _amount;
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        emit LockAmountIncreased(_user, _token, _amount);
    }

    function _increaseLockDuration(address _user, address _token, uint256 _increaseBy) internal {
        if (_userLockedToken[_user][_token].endTime >= block.timestamp) {
            _userLockedToken[_user][_token].endTime += _increaseBy;
        } else {
            _increaseBy += (block.timestamp - _userLockedToken[_user][_token].endTime);
            _userLockedToken[_user][_token].endTime += _increaseBy;
        }

        emit LockDurationIncreased(msg.sender, _token, _increaseBy);
    }

    function withdrawToken(address _user, address _token, uint256 _amount) external nonReentrant {
        if (_amount == 0) {
            return;
        }
        require(msg.sender == _userLockedToken[_user][_token].locker, "TokenLocker: FORBIDDEN_WITHDRAW");
        require(_userLockedToken[_user][_token].endTime <= block.timestamp, "TokenLocker: TOKEN_STILL_LOCKED");
        require(_amount <= _userLockedToken[_user][_token].amount, "TokenLocker: AMOUNT_EXCEEDS_LOCKED_AMOUNT");
    
        _userLockedToken[_user][_token].amount -= _amount;
    
        IERC20(_token).transfer(msg.sender, _amount);
    
        emit TokenWithdrawn(_user, _token, _amount);
    }

    function userLockedToken(address _user, address _token) external view returns(LockedToken memory) {
        return _userLockedToken[_user][_token];
    }
}