pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
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
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

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
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
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
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract WarLordSwap is Ownable, ReentrancyGuard {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	using SafeERC20 for ERC20Detailed;
	
	uint256 private _divRate = 10000;
	uint256 private _decimal = 18;
	uint256 private _decimalConverter = 10**18;
	address payable FeeAddress;
	
	struct SwapList{
		IERC20 mainToken;
		IERC20 pairToken;
		uint256 rate;
		uint256 rateDecimal;
		uint256 mainTokenFee;
		uint256 pairTokenFee;
	}
	
	SwapList[] public swapList;
		
	struct SwapTemp {
		uint256 mainTokenAmount;
		uint256 mainTokenAmountWithFee;
		uint256 pairTokenAmount;
		uint256 pairTokenAmountWithFee;
		uint256 rateAmount;
		uint256 decimalDiff;
		uint256 decimalDiffConverter;
		ERC20Detailed Token;
		uint256 TokenDecimal;
		uint256 RateDecimalConverter;
		uint256 swapAmount;
		uint256 tokenAmount;
		uint256 swapFeeAmount;
	}
	
	mapping (address => mapping (address => bool)) public existingSwaps;
		
	constructor(address payable _FeeAddress) public Ownable() {	
		FeeAddress = _FeeAddress;
		_initial_Pool();
	}
	
	function _initial_Pool() internal{
		// _addPool(address(0xdfb73e3721da66820ea034c05ebe90569847470c), address(0xb7bc7b0a32455f7e7a924f832ca4f0a0ac3b6b88), 5, 0, 0, 500);
		// _addPool(address(0x08B7F2D3647b5eC70e8bBcDeAe09Fde189F9DA70), address(0xb7bc7b0a32455f7e7a924f832ca4f0a0ac3b6b88), 125, 0, 0, 500);
	}
	
	function _addPool(address _mainToken, address _pairToken, uint256 _rate, uint256 _rateDecimal, uint256 _mainTokenFee, uint256 _pairTokenFee) internal {
		require(existingSwaps[_mainToken][_pairToken] != true, "swap exists");
		require(existingSwaps[_pairToken][_mainToken] != true, "swap exists");
		
		require(_mainTokenFee < 10000, "Fee can't be greater than 100%");
		require(_pairTokenFee < 10000, "Fee can't be greater than 100%");
		
		swapList.push(SwapList(
			IERC20(_mainToken)
			,IERC20(_pairToken)
			,_rate
			,_rateDecimal
			,_mainTokenFee
			,_pairTokenFee
		));
				
		existingSwaps[_mainToken][_pairToken] = true;
		existingSwaps[_pairToken][_mainToken] = true;
	}
	
	function addPool(address _mainToken, address _pairToken, uint256 _rate, uint256 _rateDecimal, uint256 _mainTokenFee, uint256 _pairTokenFee) external onlyOwner {
		_addPool(_mainToken,_pairToken,_rate,_rateDecimal,_mainTokenFee,_pairTokenFee);
	}
	
	function TotalPool() public view returns (uint256) {
		return swapList.length;
	}
		
	function getQuoteswapToken(uint _pid, bool _reverse, uint256 _swapAmount) public view returns (uint256) {
		SwapTemp memory temp;
		
		require(_swapAmount != 0, "Swap: Amount is 0");
		
		if(_reverse){
			temp.pairTokenAmount = _getTokenAmount(address(swapList[_pid].pairToken),_swapAmount);
			temp.rateAmount = _getReverseRateAmount(_pid,temp.pairTokenAmount);
			temp.mainTokenAmount = _getTokenAmount(address(swapList[_pid].mainToken),temp.rateAmount);
			temp.mainTokenAmountWithFee = temp.mainTokenAmount;
			
			if(swapList[_pid].mainTokenFee > 0){
				temp.swapFeeAmount = (temp.mainTokenAmount * swapList[_pid].mainTokenFee) / _divRate;
				temp.mainTokenAmountWithFee -= temp.swapFeeAmount;
			}
			
			temp.swapAmount = temp.mainTokenAmountWithFee;
			
		} else {
			temp.mainTokenAmount = _getTokenAmount(address(swapList[_pid].mainToken),_swapAmount);
			temp.rateAmount = _getRateAmount(_pid,temp.mainTokenAmount);
			temp.pairTokenAmount = _getTokenAmount(address(swapList[_pid].pairToken),temp.rateAmount);
			temp.pairTokenAmountWithFee = temp.pairTokenAmount;
			
			if(swapList[_pid].pairTokenFee > 0){
				temp.swapFeeAmount = (temp.pairTokenAmount * swapList[_pid].pairTokenFee) / _divRate;
				temp.pairTokenAmountWithFee -= temp.swapFeeAmount;
			}
			
			temp.swapAmount = temp.pairTokenAmountWithFee;
		}
		
		return temp.swapAmount;
	}
		
	function swapToken(uint _pid, bool _reverse, uint256 _swapAmount) external nonReentrant {
		SwapTemp memory temp;
		
		require(_swapAmount != 0, "Swap: Amount is 0");
		
		if(_reverse){
			temp.pairTokenAmount = _getTokenAmount(address(swapList[_pid].pairToken),_swapAmount);
			temp.rateAmount = _getReverseRateAmount(_pid,temp.pairTokenAmount);
			temp.mainTokenAmount = _getTokenAmount(address(swapList[_pid].mainToken),temp.rateAmount);
			temp.mainTokenAmountWithFee = temp.mainTokenAmount;
			
			emit SwapToken(msg.sender, address(swapList[_pid].pairToken),  temp.pairTokenAmount,  address(swapList[_pid].mainToken),  temp.mainTokenAmount);
						
			
			
			if(swapList[_pid].mainTokenFee > 0){
				temp.swapFeeAmount = (temp.mainTokenAmount * swapList[_pid].mainTokenFee) / _divRate;
				emit SwapFee(msg.sender, address(swapList[_pid].mainToken), swapList[_pid].mainTokenFee, temp.swapFeeAmount);	
				temp.mainTokenAmountWithFee -= temp.swapFeeAmount;
			}
			
			swapList[_pid].pairToken.safeTransferFrom(msg.sender, address(this), temp.pairTokenAmount);
			swapList[_pid].mainToken.safeTransfer(msg.sender, temp.mainTokenAmountWithFee);
			if(temp.swapFeeAmount > 0){
				swapList[_pid].mainToken.safeTransfer(FeeAddress, temp.swapFeeAmount);
			}
			
		} else {
			temp.mainTokenAmount = _getTokenAmount(address(swapList[_pid].mainToken),_swapAmount);
			temp.rateAmount = _getRateAmount(_pid,temp.mainTokenAmount);
			temp.pairTokenAmount = _getTokenAmount(address(swapList[_pid].pairToken),temp.rateAmount);
			temp.pairTokenAmountWithFee = temp.pairTokenAmount;
			
			emit SwapToken(msg.sender, address(swapList[_pid].mainToken),  temp.mainTokenAmount,  address(swapList[_pid].pairToken),  temp.pairTokenAmount);
			
			
			
			if(swapList[_pid].pairTokenFee > 0){
				temp.swapFeeAmount = (temp.pairTokenAmount * swapList[_pid].pairTokenFee) / _divRate;
				emit SwapFee(msg.sender, address(swapList[_pid].mainToken), swapList[_pid].pairTokenFee, temp.swapFeeAmount);	
				temp.pairTokenAmountWithFee -= temp.swapFeeAmount;
			}
			
			swapList[_pid].mainToken.safeTransferFrom(msg.sender, address(this), temp.mainTokenAmount);
			swapList[_pid].pairToken.safeTransfer(msg.sender, temp.pairTokenAmountWithFee);
			if(temp.swapFeeAmount > 0){
				swapList[_pid].pairToken.safeTransfer(FeeAddress, temp.swapFeeAmount);
			}
		}
	}
	
	function _getTokenAmount(address _tokenAddress, uint256 _swapAmount) internal view returns (uint256 quotient) {
		SwapTemp memory temp;
		
		temp.Token = ERC20Detailed(_tokenAddress);
		temp.TokenDecimal = temp.Token.decimals();
			
		if(_decimal != temp.TokenDecimal){
			if(_decimal > temp.TokenDecimal){
				temp.decimalDiff = _decimal - temp.TokenDecimal;
				temp.decimalDiffConverter = 10**temp.decimalDiff;
				temp.swapAmount = _swapAmount.div(temp.decimalDiffConverter);
			} else {
				temp.decimalDiff = temp.TokenDecimal - _decimal;
				temp.decimalDiffConverter = 10**temp.decimalDiff;
				temp.swapAmount = _swapAmount.mul(temp.decimalDiffConverter);
			}		
		} else {
			temp.swapAmount = _swapAmount;
		}
		
		uint256 _quotient = temp.swapAmount;
		
		return (_quotient);
    }
		
	function _getRateAmount(uint _pid, uint256 _swapAmount) internal view returns (uint256) {
		SwapTemp memory temp;
		
		if(swapList[_pid].rateDecimal > 0){
			temp.RateDecimalConverter = 10**swapList[_pid].rateDecimal;
			
			temp.swapAmount = _swapAmount.mul(swapList[_pid].rate);
			temp.swapAmount = temp.swapAmount.div(temp.RateDecimalConverter);
		} else {
			temp.swapAmount = _swapAmount.mul(swapList[_pid].rate);
		}

	   return temp.swapAmount;
    }
	
	function _getReverseRateAmount(uint _pid, uint256 _swapAmount) internal view returns (uint256) {
		SwapTemp memory temp;
		
		if(swapList[_pid].rateDecimal > 0){
			temp.RateDecimalConverter = 10**swapList[_pid].rateDecimal;
			
			temp.swapAmount = _swapAmount.div(swapList[_pid].rate);
			temp.swapAmount = temp.swapAmount.mul(temp.RateDecimalConverter);
		} else {
			temp.swapAmount = _swapAmount.div(swapList[_pid].rate);
		}

	   return temp.swapAmount;
    }
	
	function changeRate(uint _pid, uint256 _rate, uint256 _rateDecimal) external onlyOwner{
		uint256 countSwap = swapList.length;
		require(_pid < countSwap, "Not a valid Pair");
		
		swapList[_pid].rate = _rate;
		swapList[_pid].rateDecimal = _rateDecimal;
	}
	
	function changeFee(uint _pid, uint256 _mainTokenFee, uint256 _pairTokenFee) external onlyOwner{
		uint256 countSwap = swapList.length;
		require(_pid < countSwap, "Not a valid Pair");
		
		swapList[_pid].mainTokenFee = _mainTokenFee;
		swapList[_pid].pairTokenFee = _pairTokenFee;
	}
	
	function _deliverTokens(address _tokenAddress, address account) external onlyOwner {
		SwapTemp memory temp;
		
		temp.Token = ERC20Detailed(_tokenAddress);
		temp.TokenDecimal = temp.Token.decimals();
		temp.tokenAmount = temp.Token.balanceOf(address(this));
		
		IERC20(_tokenAddress).safeTransfer(account, temp.tokenAmount);
		
	}
		
	function _deliverETH(address payable wallet, uint256 ETHamount) external onlyOwner {
		wallet.transfer(ETHamount);
	}
	
	function changeFeeAddress(address payable _newFeeAddress) external onlyOwner{
		FeeAddress = _newFeeAddress;
	}
	
	event SwapFee(address indexed user, address token, uint256 fee, uint256 amount);
	event SwapToken(address indexed user, address token0,  uint256 amount0,  address token1,  uint256 amount1);
}