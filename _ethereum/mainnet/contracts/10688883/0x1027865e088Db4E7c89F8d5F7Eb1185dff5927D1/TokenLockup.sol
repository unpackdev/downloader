pragma solidity ^0.5.0;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require((value == 0) || (token.allowance(address(this), spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}

/*
 * Copyright 2020 Dolomite
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
/**
 * This was copied from OpenZeppelin's TokenLockup contract to work for solidity version 5.0.
 */
contract TokenLockup is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Released(uint256 amount);
    event Revoked();

    // beneficiary of tokens after they are released
    address public beneficiary;

    uint256 public cliff;
    uint256 public start;
    uint256 public duration;

    bool public revocable;

    mapping(address => uint256) public released;
    mapping(address => bool) public revoked;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
     * of the balance will have vested.
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _startTimestamp the time (as Unix time) at which point vesting starts
     * @param _cliffDurationInSeconds duration in seconds of the cliff in which tokens will begin to vest
     * @param _durationInSeconds duration in seconds of the period in which the tokens will vest
     * @param _revocable whether the vesting is revocable or not
     */
    constructor(
        address _beneficiary,
        uint256 _startTimestamp,
        uint256 _cliffDurationInSeconds,
        uint256 _durationInSeconds,
        bool _revocable
    )
    public
    {
        require(_beneficiary != address(0), "TokenLockup::constructor: INVALID_BENEFICIARY");
        require(_cliffDurationInSeconds <= _durationInSeconds, "TokenLockup::constructor: INVALID_DURATION");

        beneficiary = _beneficiary;
        revocable = _revocable;
        duration = _durationInSeconds;
        cliff = _startTimestamp.add(_cliffDurationInSeconds);
        start = _startTimestamp;
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     * @param _token ERC20 token which is being vested
     */
    function release(IERC20 _token) public {
        uint256 unreleased = releasableAmount(_token);

        require(unreleased > 0, "TokenLockup::constructor: NOT_RELEASABLE");

        released[address(_token)] = released[address(_token)].add(unreleased);

        _token.safeTransfer(beneficiary, unreleased);

        emit Released(unreleased);
    }

    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     * remain in the contract, the rest are returned to the owner.
     * @param _token ERC20 token which is being vested
     */
    function revoke(IERC20 _token) public onlyOwner {
        require(revocable, "TokenLockup::revoke: NOT_REVOCABLE");
        require(!revoked[address(_token)], "TokenLockup::revoke: ALREADY_REVOKED");

        uint256 balance = _token.balanceOf(address(this));

        uint256 unreleased = releasableAmount(_token);
        uint256 refund = balance.sub(unreleased);

        revoked[address(_token)] = true;

        _token.safeTransfer(owner(), refund);

        emit Revoked();
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     * @param _token ERC20 token which is being vested
     */
    function releasableAmount(IERC20 _token) public view returns (uint256) {
        return vestedAmount(_token).sub(released[address(_token)]);
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param _token ERC20 token which is being vested
     */
    function vestedAmount(IERC20 _token) public view returns (uint256) {
        uint256 currentBalance = _token.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(released[address(_token)]);

        if (block.timestamp < cliff) {
            return 0;
        } else if (block.timestamp >= start.add(duration) || revoked[address(_token)]) {
            return totalBalance;
        } else {
            return totalBalance.mul(block.timestamp.sub(start)).div(duration);
        }
    }
}