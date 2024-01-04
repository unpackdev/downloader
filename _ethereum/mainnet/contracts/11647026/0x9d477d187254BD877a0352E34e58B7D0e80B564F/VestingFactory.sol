// File: browser/SafeERC20.sol


pragma solidity ^0.5.2;





/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require((value == 0) || (token.allowance(address(this), spender) == 0));
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must equal true).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.

        require(address(token).isContract());

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success);

        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)));
        }
    }
}

// File: browser/Address.sol

// File: openzeppelin-solidity/contracts/utils/Address.sol

pragma solidity ^0.5.2;

/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: browser/SafeMath.sol

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.2;

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

// File: browser/IERC20.sol

pragma solidity ^0.5.2;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
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
// File: browser/TokenVesting.sol

pragma solidity 0.5.17;





/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting {
    // The vesting schedule is time-based (i.e. using block timestamps as opposed to e.g. block numbers), and is
    // therefore sensitive to timestamp manipulation (which is something miners can do, to a certain degree). Therefore,
    // it is recommended to avoid using short time durations (less than a minute). Typical vesting schemes, with a
    // cliff period of a year and a duration of four years, are safe to use.
    // solhint-disable not-rely-on-time

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event TokensReleased(uint256 mTokensAmount, uint256 sTokensAmount);

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
    uint256 private _cliff;
    uint256 private _start;
    uint256 private _duration;

    address public mainToken;
    
    address public secondaryToken;
    
    uint256 public multiplier;
    
    address public factory;
    
    uint256 public totalVestingAmount;
    
    mapping (address => uint256) private _released;
    
    
    constructor (address beneficiary, uint256 amount, uint256 start, uint256 cliffDuration, uint256 duration, address _mainToken, address _secondaryToken, uint256 _multipier) public {
        require(beneficiary != address(0));
        require(cliffDuration <= duration);
        require(duration > 0);
        require(start.add(duration) > block.timestamp);

        _beneficiary = beneficiary;
        _duration = duration;
        _cliff = start.add(cliffDuration);
        _start = start;
        mainToken = _mainToken;
        secondaryToken = _secondaryToken;
        multiplier = _multipier;
        factory = msg.sender;
        totalVestingAmount = amount;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the cliff time of the token vesting.
     */
    function cliff() public view returns (uint256) {
        return _cliff;
    }

    /**
     * @return the start time of the token vesting.
     */
    function start() public view returns (uint256) {
        return _start;
    }

    /**
     * @return the duration of the token vesting.
     */
    function duration() public view returns (uint256) {
        return _duration;
    }
    
    /**
     * @return the amount of the token released.
     */
    function available() public view returns (uint256) {
        return totalVestingAmount.sub(_released[mainToken]);
    }
    
    /**
     * @return the amount of the token released.
     */
    function released(address token) public view returns (uint256) {
        return (_released[token]);
    }
    
    /**
     * @return the amount of secondary tokens that has been accrued but hasn't been released yet.
     */
    function _accruedAmount() public view returns (uint256) {
        return _releasableAmount().mul(multiplier).div(10000);
    }
  
 
    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release() public {
        uint256 unreleased = _releasableAmount();
        

        require(unreleased > 0);
        
        uint256 sTokensToRelease = unreleased.mul(multiplier).div(10000);

        _released[mainToken] = _released[mainToken].add(unreleased);
        _released[secondaryToken] = _released[secondaryToken].add(sTokensToRelease);


        IERC20(mainToken).safeTransfer(_beneficiary, unreleased);
        IERC20(secondaryToken).safeTransferFrom(factory, _beneficiary, sTokensToRelease);

        emit TokensReleased(unreleased, sTokensToRelease);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     */
    function _releasableAmount() private view returns (uint256) {
        return _vestedAmount().sub(_released[mainToken]);
    }
    

    /**
     * @dev Calculates the amount that has already vested.
     */
    function _vestedAmount() private view returns (uint256) {
       

        if (block.timestamp < _cliff) {
            return 0;
        } else if (block.timestamp >= _start.add(_duration)) {
            return totalVestingAmount;
        } else {
            return totalVestingAmount.mul(block.timestamp.sub(_start)).div(_duration);
        }
    }
}
// File: browser/VestingFactory.sol

pragma solidity 0.5.17;






contract VestingFactory {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    uint256 public cliffTime;
    
    uint256 public duration;
    
    uint256 public multipier;
    
    address public mainToken;
    
    address public secondaryToken;
    
    
    uint256 public maxVesting;
    
    uint256 public currentVestedAmount;
    
    mapping(address => address[]) public userVsVesting;
    
    event Vested(address indexed user, address indexed vestingContract);
    
    constructor(
        uint256 _cliffTime,
        uint256 _duration,
        uint256 _multipier,
        address _mainToken,
        address _secondaryToken,
        uint256 _maxVesting
    )
        public
    {
        cliffTime = _cliffTime;
        duration = _duration;
        multipier = _multipier;
        mainToken = _mainToken;
        secondaryToken = _secondaryToken;
        maxVesting = _maxVesting;
    }
    
    function vest(uint256 amount) external {
        
        require(currentVestedAmount.add(amount) <= maxVesting, "Breaching max vesting limit");
        currentVestedAmount = currentVestedAmount.add(amount);
        uint256 cliff = 0;
        
        if (cliffTime > block.timestamp) {
            cliff = cliffTime.sub(block.timestamp);
        }
        
        
        TokenVesting vesting = new TokenVesting(
            msg.sender,
            amount,
            block.timestamp,
            cliff,
            duration,
            mainToken,
            secondaryToken,
            multipier
        );
        
        userVsVesting[msg.sender].push(address(vesting));
        IERC20(mainToken).safeTransferFrom(msg.sender, address(vesting), amount);
        IERC20(secondaryToken).safeApprove(address(vesting), amount.mul(multipier).div(10000));
        
        emit Vested(msg.sender, address(vesting));
        
    }
    
    function userContracts(address user) public view returns(address[] memory){
        return userVsVesting[user];
    }
    
    function accruedAmount(address user) public view returns(uint256){
        uint256 amount = 0;
        for(uint i=0; i<userVsVesting[user].length;i++){
           amount = amount.add(TokenVesting(userVsVesting[user][i])._accruedAmount()); 
        }
        return amount;
    }
    
    function mainTokenBalance(address user) public view returns(uint256){
        uint256 amount = 0;
        for(uint i=0; i<userVsVesting[user].length;i++){
           amount = amount.add(TokenVesting(userVsVesting[user][i]).available()); 
        }
        return amount;
    }
    
}