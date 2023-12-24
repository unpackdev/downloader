// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10 >=0.8.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Vesting is Context {

    struct VestingInfo {
        uint256 timeLimit;
        uint256 amount;
    }

    mapping(address => mapping(address => VestingInfo)) public locks;
    mapping(address => address[]) public myLocks;

    event TokenLocked(address indexed token, uint256 amount, uint256 timelimit);
    event TokenClaimed(address indexed token, uint256 amount, address receiver);

    constructor() {}

    function lock(
        address token,
        uint256 amount,
        uint256 lockTime
    ) public {
        address sender = _msgSender();
        VestingInfo memory _vesting = locks[sender][token];

        require(lockTime >= _vesting.timeLimit, "MUST BE GREATER");
        IERC20(token).transferFrom(sender, address(this), amount);

        _vesting.amount += amount;
        _vesting.timeLimit = lockTime;

        locks[sender][token] = _vesting;
        myLocks[sender].push(token);

        emit TokenLocked(token, amount, lockTime);
    }

    function unlock(
        address token,
        address receiver
    ) public {
        address sender = _msgSender();
        VestingInfo memory _vesting = locks[sender][token];
        uint256 amount = _vesting.amount;

        require(block.timestamp > _vesting.timeLimit, "CANNOT UNLOCK");
        IERC20(token).transfer(receiver, amount);

        _vesting.amount = 0;
        _vesting.timeLimit = 0;

        locks[sender][token] = _vesting;

        popLock(sender, token);

        emit TokenClaimed(token, amount, receiver);
    }

    function timeRemains(
        address owner,
        address token
    ) public view returns (uint256) {
        VestingInfo memory _vesting = locks[owner][token];
        return _vesting.timeLimit < block.timestamp? 0: block.timestamp - _vesting.timeLimit;
    }

    function popLock(
        address sender,
        address token
    ) internal {
        for(uint256 i = 0; i < myLocks[sender].length; ++i) {
            if (myLocks[sender][i] == token) {
                myLocks[sender][i] = myLocks[sender][myLocks[sender].length - 1];
                myLocks[sender].pop();
            }
        }
    }
}