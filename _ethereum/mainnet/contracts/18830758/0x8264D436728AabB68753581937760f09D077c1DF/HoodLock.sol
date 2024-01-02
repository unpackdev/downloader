// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract HoodLock is Context, Ownable {
    event TokensLocked();
    event TokensReleased(uint256 releaseAmount);

    IERC20 public _token;

    bool private _locked;
    address public _beneficiary;
    uint256 public _releasedAmount;
    uint256 public _startTime;
    uint256 public _cliffDuration;
    uint256 public _cliffAmount;
    uint256 public _numSteps;
    uint256 public _stepDuration;
    uint256 public _stepAmount;

    constructor() {
        _token = IERC20(0x04815313E9329e8905A77251A1781CfA7934259a);
    }

    function lockTokens(
        address beneficiary,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 cliffAmount,
        uint256 numSteps,
        uint256 stepDuration,
        uint256 stepAmount
    ) external onlyOwner
    {
        require(!_locked, "already locked");
        require(beneficiary != address(0), "beneficiary is the zero address");
        require(startTime + cliffDuration > block.timestamp, "cliff end time is before current time");
        require(cliffDuration > 0, "cliffDuration is 0");
        require(cliffAmount > 0, "cliffAmount is 0");
        require(numSteps > 0, "numSteps is 0");
        require(stepDuration > 0, "stepDuration is 0");
        require(stepAmount > 0, "stepAmount is 0");

        _beneficiary = beneficiary;
        _startTime = startTime;
        _cliffDuration = cliffDuration;
        _cliffAmount = cliffAmount;
        _numSteps = numSteps;
        _stepDuration = stepDuration;
        _stepAmount = stepAmount;
        _token.transferFrom(_msgSender(), address(this), totalAmount());
        _locked = true;
        emit TokensLocked();
    }

    function releaseTokens() external onlyOwner {
        require(_locked, "not locked");
        require(_beneficiary == _msgSender(), "caller is not the beneficiary");

        require(_releasedAmount < totalAmount(), "all tokens released");

        uint256 unlockedAmountValue = unlockedAmount();
        require(unlockedAmountValue > 0, "called before cliff end");

        uint256 releasableAmountValue = unlockedAmountValue - _releasedAmount;
        require(releasableAmountValue > 0, "called before current step end");

        _releasedAmount = _releasedAmount + releasableAmountValue;
        _token.transfer(_beneficiary, releasableAmountValue);
        emit TokensReleased(releasableAmountValue);
    }

    function totalAmount() public view returns (uint256) {
        return _cliffAmount + (_stepAmount * _numSteps);
    }

    function unlockedAmount() public view returns (uint256) {
        uint256 cliffEnd = _startTime + _cliffDuration;
        if (block.timestamp < cliffEnd) {
            return 0;
        } else if (block.timestamp >= cliffEnd + (_stepDuration * _numSteps)) {
            return totalAmount();
        } else {
            uint256 unlockedSteps = (block.timestamp - cliffEnd) / _stepDuration;
            return _cliffAmount + (_stepAmount * unlockedSteps);
        }
    }

    function releasableAmount() public view returns (uint256) {
        return unlockedAmount() - _releasedAmount;
    }

    function cliffUnlockTime() public view returns (uint256) {
        return _startTime + _cliffDuration;
    }

    function stepUnlockTime(uint256 stepNumber) public view returns (uint256) {
        if (!_locked) {
            return 0;
        }
        require(stepNumber > 0, "stepNumber is 0");
        require(stepNumber <= _numSteps, "stepNumber is greater than the number of steps");
        return cliffUnlockTime() + (_stepDuration * stepNumber);
    }

    function nextUnlockTime() public view returns (uint256) {
        uint256 cliffEnd = cliffUnlockTime();
        uint256 lastStepEnd = stepUnlockTime(_numSteps);
        if (block.timestamp < cliffEnd) {
            return cliffEnd;
        } else if (block.timestamp >= lastStepEnd) {
            return lastStepEnd;
        } else {
            uint256 unlockedSteps = (block.timestamp - cliffEnd) / _stepDuration;
            return stepUnlockTime(unlockedSteps + 1);
        }
    }
}