//SPDX-License-Identifier: stupid


pragma solidity >= 0.4;

library SafeMath{
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
    
        /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    
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
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
}
interface IUniswapV2Pair {

    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    
}

contract UNI_PRICE {
    using SafeMath for uint112;
    using SafeMath for uint256;
    
    address public UNIfactory;
    address public wETHaddress;
    address public owner;
 
    modifier onlyOwner {
        require(msg.sender == owner, "only owner");
        _;
    }
    
    constructor(address _UNIfactory, address _wETHaddress) public {
        owner = msg.sender;
        UNIfactory = _UNIfactory; 
        //0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; MAINNET ETH
        
        wETHaddress = _wETHaddress; 
        //0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2; MAINNET ETH
    }
    
    
    function getUNIpair(address _token) internal view returns(address) {
        return IUniswapV2Factory(UNIfactory).getPair(_token, wETHaddress);
    }
    function _getUint256Reserves(address _token) internal view returns(uint256 rToken, uint256 rWETH) {
        address _UNIpair = getUNIpair(_token);
                
        address _token0 = IUniswapV2Pair(_UNIpair).token0(); 
        address _token1 = IUniswapV2Pair(_UNIpair).token1(); 
        require(_token0 == wETHaddress || _token1 == wETHaddress);
        
        uint112 _rTKN; uint112 _rWETH;
        
        if(_token0 == wETHaddress) {
        (_rWETH, _rTKN, ) = IUniswapV2Pair(_UNIpair).getReserves(); //returns r0, r1, time
        }
        else {
        (_rTKN, _rWETH, ) = IUniswapV2Pair(_UNIpair).getReserves();
        }
        
        return (uint256(_rTKN),uint256(_rWETH)); //price in gwei, needs to be corrected by nb of decimals of _token
         //price of 1 token in GWEI
    }  
    
    function adjuster(address _token) internal view returns(uint256) {
        uint8 _decimals = IERC20(_token).decimals();
        require(_decimals <= 18,"OverFlow risk, not supported");
        uint256 _temp = 36 - uint256(_decimals);
        return 10**_temp;
    }
    
    function getUNIprice(address _token) internal view returns(uint) {

        uint256 rToken; uint256 rWETH; uint256 _adjuster;
        (rToken, rWETH) = _getUint256Reserves(_token);
        _adjuster = adjuster(_token);
        

        return ( (rToken).mul(_adjuster) ).div(rWETH);       //IN GWEI
    }
    
    function getTokenInfo(address _token) public view returns(
        string memory name, string memory symbol, uint8 decimals, address uniPair, uint256 tokensPerETH) {
        return(
            IERC20(_token).name(), 
            IERC20(_token).symbol(), 
            IERC20(_token).decimals(), 
            getUNIpair(_token), 
            getUNIprice(_token)
            ); //normalized as if every token is 18 decimals
    }
  
//ERC20_utils  
    function widthdrawAnyToken(address _token) external onlyOwner returns (bool) {
        uint256 _amount = IERC20(_token).balanceOf(address(this));
        _widthdrawAnyToken(msg.sender, _token, _amount);
        return true;
    } //get tokens sent by error to contract
    function _widthdrawAnyToken(address _recipient, address _ERC20address, uint256 _amount) internal returns (bool) {
        IERC20(_ERC20address).transfer(_recipient, _amount); //use of the _ERC20 traditional transfer
        return true;
    } //get tokens sent by error
    function kill() public onlyOwner{
            selfdestruct(msg.sender);
        } //frees space on the ETH chain
}