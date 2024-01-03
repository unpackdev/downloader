pragma solidity ^0.6.6;




interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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



abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


contract UniPart is Ownable{
    using SafeMath for uint256;
    using Address for address;

    address public constant unifactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    IUniswapV2Factory public factory;
    IUniswapV2Router02 public uniswapRouter;

    event CreateUniPairEvent(address uniPair, uint timeStamp);
    event InitialPairEvent(uint256 DecexIn, uint256 ETHIN, uint timeStamp);
     

    uint public constant initialDecexIn = 40e18; //add with 0.1 eth

  
   
    function createPair() public onlyOwner returns (address){
        address uniPair;
        if (factory.getPair(address(this), uniswapRouter.WETH()) == address(0)) {
            uint createdTime =  block.timestamp;
            
            uniPair = factory.createPair(address(this), uniswapRouter.WETH());
          
            emit CreateUniPairEvent(uniPair,createdTime);
            
        }else{
            uniPair = factory.getPair(address(this), uniswapRouter.WETH());
        }

        return uniPair;
    }


    function initialPair() public payable onlyOwner returns (bool){   //create pair with liquidity and add pair and uniswap routerV2 to white list to enable buy and sell

        uint deadline = block.timestamp + 15;

        IERC20 DecexToken = IERC20(address(this));

        require(DecexToken.approve(address(UNISWAP_ROUTER_ADDRESS), initialDecexIn), 'approve failed.');
        // require(WETHToken.approve(address(UNISWAP_ROUTER_ADDRESS), initialETHIn), 'approve failed.');

        uniswapRouter.addLiquidityETH{ value: msg.value }(address(this), initialDecexIn , initialDecexIn, msg.value ,address(this),deadline);

    
        emit InitialPairEvent(initialDecexIn, msg.value ,deadline );

        return true;
    }

    function getPair() public  view returns (address){
        return factory.getPair(address(this), uniswapRouter.WETH());
       
    }


    

}

contract ManagementPart is  UniPart {
    using SafeMath for uint256;
    using Address for address;

    address public uniPair;
    mapping (address => bool) public _whiteList;
    mapping (address => bool) public _frozenAccount;

  
    event FrozenAccountEvent(address account, bool frozen);
    event ChangeWhiteListEvent(address account, bool isWhite);
   

    function addWhiteList(address _user) public onlyOwner {
        require(_user != address(0), "Ownable: new owner is the zero address");
        require(_frozenAccount[msg.sender] != true, "sender was frozen" );
        _whiteList[_user] = true;
        emit ChangeWhiteListEvent( _user, true);
    }

    function removeWhiteList(address _user) public onlyOwner {
        require(_user != address(0), "Ownable: new owner is the zero address");
        require(_frozenAccount[msg.sender] != true, "sender was frozen" );
        _whiteList[_user] = false;
         emit ChangeWhiteListEvent( _user, false);
    }

    function freezeAccount(address target, bool freeze) public onlyOwner {
        
        _frozenAccount[target] = freeze;
        emit FrozenAccountEvent( target, freeze);
    }



    function isWhiteList(address account) public view  returns (bool) {
        return _whiteList[account];
    }


    
   
}

contract DECEXERC20 is ManagementPart,IERC20 {
    using SafeMath for uint256;
    using Address for address;
   
 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    ///////////////public usage part/////////////////////

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) public _balances; 
    uint256 public _totalSupply; 
    string  public _name;
    string  public _symbol;
    uint8   public _decimals;
    

    ///////////////UniSwap part//////////////////////////

 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    ///////////////token distribution part/////////////////////

    uint256 public constant MaxSupply = 1000000e18;
    uint256 public  initialSupply; 


    ///////////////10% for airDrop and Marketing////////////

    //mint 1% for public airdrop
    //mint 0.5% for CoreAirdrop
    uint256 public constant forAirdropSociety = 5000e18; //0.5%
    uint256 public constant forAirdropMedia = 5000e18; //0.5%
    uint256 public constant forMarketing = 80000e18; //8%
    ////////////////////////////////////////////////////////

    
    uint256 public constant forSeedSell = 50000e18; //5%
    uint256 public constant forGenesisStakingPool = 50000e18; //lock 30 days 5%
    uint256 public constant forLaterProgress = 100000e18; //lock 90 days 10%
    uint256 public constant forProjectKeep = 50000e18; // lock 90 days 5%

    uint256 public constant initialLiquidity = 40e18;   ///40 dcx for initail uniswap pool
    uint256 public constant forLiquidity = 199960e18; //20% 40 decex for initial liquidity


    uint256 public constant forPublicSell = 450000e18; //45% 45w decex for PublicSellContract

    
  

    address public _forAirdropSocietyAddress = address(0xe2E68a22A3Ad7B8181b6A6bFC8a985B4c7c5367D); 
    address public _forAirdropMediaAddress = address(0xF26C3875b2BA60FEcDcec2c615c85FbD139a1503); 
    address public _forMarketingAddress = address(0xf2342b1D5154C0f06F1eb7E8d09f0e71Ba103734); 
    address public _forSeedSellAddress = address(0x8353B27a37C4bFb648A510358998AEEdBF68D9d0); 


    address public _forGenesisStakingPoolAddress = address(0x1ca7163c8C323F14d5054e28Eac2DF196bCd104f); //10%  lock 30 days //5
    address public _forLaterProgressAddress = address(0xF662B5c689c8382367aFEDbdBFa9085EF07Af3AB); //10% lock 90 days //6
    address public _forProjectKeepAddress = address(0xC564b835AAdF56De1884FED770643a61eB0426A7); //5% lock 90 days //7
    address public _forLiquidPoolAddress = address(0x695493347bb71bF68683bC0628dd1180dbc39d61);  //20% //8

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //////charge part burn////////

   
    uint256 public constant _rateBase = 100000;
    uint256 public _totalBurnToken = 0; //c
    uint256 public constant _maxBurnAmount = 799083e18; //c 799083e18

    address public _burnAddress = address(0);
    uint256 public _toBurn_rate = 1000;
    uint256 public _toLiquidity_rate = 1000;
    uint256 public _toBuyBack_rate  = 2000;
    uint256 public _toProject_rate = 1000;

    address public _toLiquidPoolChargeAddress = address(0); //9  contract address
    address public _toBuyBackPoolChargeAddress = address(0x14A777403FCe6271A4b5fce7a27c866f33671ade); //10
    address public _toProjectPoolChargeAddress= address(0xcB1350E994d8BcbA55575ABe429D953e2B4a7208); //11

    event DecexChargeFeeEvent(address sender ,uint256 burn, uint256 toLiquidity, uint256 buyBack , uint256 toProject);
    event TransferToPoolEvent( address poolAddress, uint256 value);
    event SetToLiquidPoolEvent(address newPool);
    event SetToBuyBack_PoolEvent(address newPool);
    event SetToProjectPoolEvent(address newPool);
    event SetChargeFeeEvent(uint256 new_toBurn_rate, uint256 new_toLiquidity_rate, uint256 new_toBuyBack_rate , uint256 new_toProject_rate);

    
     function setChargeFee(
        uint256 toBurn_rate, 
        uint256 toLiquidity_rate, 
        uint256 toBuyBack_rate,  
        uint256 toProject_rate
    ) public  onlyOwner{
        require(toBurn_rate > 0 &&  toBurn_rate < _rateBase, "toBurn rate must more than zero" );
        require(toLiquidity_rate > 0 &&  toLiquidity_rate < _rateBase, "toLiquidity rate must more than zero" );
        require(toBuyBack_rate > 0 &&  toBuyBack_rate < _rateBase, "toBuyBack rate must more than zero" );
        require(toProject_rate > 0 &&  toProject_rate < _rateBase, "toProject rate must more than zero" );
        require(_frozenAccount[msg.sender] != true, "sender was frozen" );
        require(_toLiquidPoolChargeAddress != address(0), "toLiquidPool not set" );
        require(_toBuyBackPoolChargeAddress != address(0), "toBuyBackPool not set" );
        require(_toProjectPoolChargeAddress != address(0), "toProjectPool not set" );
        

        _toBurn_rate = toBurn_rate;
        _toLiquidity_rate = toLiquidity_rate;
        _toBuyBack_rate  = toBuyBack_rate;
        _toProject_rate = toProject_rate;

        emit SetChargeFeeEvent(toBurn_rate, toLiquidity_rate, toBuyBack_rate, toProject_rate);          
    }


    function setToLiquidPool(
       address payable newPoolAddress
    ) public  onlyOwner{
        require(newPoolAddress != address(0), "invild address" );
        require(_frozenAccount[msg.sender] != true, "sender was frozen" );

        _toLiquidPoolChargeAddress = newPoolAddress;

        emit SetToLiquidPoolEvent( newPoolAddress);
    }

    function setToBuyBack_Pool(
       address payable newPoolAddress
    ) public  onlyOwner{
        require(newPoolAddress != address(0), "invild address" );
        require(_frozenAccount[msg.sender] != true, "sender was frozen" );

        _toBuyBackPoolChargeAddress = newPoolAddress;

        emit SetToBuyBack_PoolEvent(newPoolAddress);
    }

    function setToProjectPool(
       address payable newPoolAddress
    ) public  onlyOwner{
        require(newPoolAddress != address(0), "invild address" );
        require(_frozenAccount[msg.sender] != true, "sender was frozen" );

        _toProjectPoolChargeAddress = newPoolAddress;

        emit SetToProjectPoolEvent(newPoolAddress);
    }


    function getPoolAddresses() public view returns (address,address,address){

        return (_toLiquidPoolChargeAddress,_toBuyBackPoolChargeAddress, _toProjectPoolChargeAddress);
    }


    function _transferToPool(
        address sender,
         address poolAddress, uint256 amount
    ) internal virtual {
        require(amount > 0 , "ERC20: transfer amount less than zero 1 ");


        _transfer(sender, poolAddress, amount);
    }

    function _charge(uint256 amountBefore, address sender) 
        internal
        virtual
        returns (uint256){
        
        require(amountBefore > 0 , "ERC20: transfer amount less than zero 2");
         
        uint256 liquidityFee = amountBefore.mul(_toLiquidity_rate).div(_rateBase);
        uint256 buyBackFee = amountBefore.mul(_toBuyBack_rate).div(_rateBase);
        uint256 toProjectFee = amountBefore.mul(_toProject_rate).div(_rateBase);
        uint256 burnFee = amountBefore.mul(_toBurn_rate).div(_rateBase);


         if (burnFee > 0) {
                //to burn
            if(_totalBurnToken < _maxBurnAmount){
                amountBefore = amountBefore.sub(burnFee,'x1');
                _totalBurnToken = _totalBurnToken.add(burnFee);
                _transferToPool(sender,_burnAddress,burnFee);
            }     
        }

        if (liquidityFee > 0) {
            //to liquidPool toooooooooooo be implmented more specific
            amountBefore = amountBefore.sub(liquidityFee,'x2');
            _transferToPool(sender, _toLiquidPoolChargeAddress, liquidityFee );
        }

        if (buyBackFee > 0) {
            //to buybackAddress
            amountBefore = amountBefore.sub(buyBackFee,'x3');
            _transferToPool(sender, _toBuyBackPoolChargeAddress, buyBackFee );
        }

        if (toProjectFee> 0) {
            //to projectAddress
            amountBefore = amountBefore.sub(toProjectFee,'x4');
            _transferToPool(sender, _toProjectPoolChargeAddress, toProjectFee );
        }

        return (amountBefore);   
    }

    
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//interface for Selling and Airdrop//


 mapping(address => bool) public allowedAddress;


 event AddActivityAddressEvent(uint8 activityIndex ,address account);
 event SendDcxEvent(uint8 activityIndex ,address ToAccount, uint256 amount);



 uint256 public constant publicAirdropTargetAmount = 10000e18;
 uint256 public publicAirdropMintAmount;


   function setActivityAddress(address account, uint8 lableIndex, bool turnOff) public onlyOwner {
        require(account != address(0), "zero address");
        require(_frozenAccount[msg.sender] != true, "sender was frozen" );
        
        allowedAddress[account] = turnOff;
       
      
        emit AddActivityAddressEvent( lableIndex, account);
    }


    function sendDcx(address account, uint256 amount , uint8 activityIndex) public {
        require(allowedAddress[msg.sender],'the address is not allowed, only activities contract address allowed');

        require(account != address(0), "zero address");
        require(amount > 0 , "invalid amount input");

        if(activityIndex == 99 ){

             require(publicAirdropMintAmount.add(amount) <= publicAirdropTargetAmount,"exceed");

              _mint(account,amount,activityIndex);

              publicAirdropMintAmount = publicAirdropMintAmount.add(amount);

        }

    }

    function queryPublicAirDropMintStatus() public view returns (uint256 ,uint256){
        return (publicAirdropMintAmount,publicAirdropTargetAmount);
    }

    function _mint(address account, uint256 amount, uint8 activityIndex) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        require(_totalSupply.add(amount) <= MaxSupply, "mint exceed maxSupply");

      

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);

        emit SendDcxEvent(activityIndex, account, amount);
    }

    function checkAddress(address account) public view returns (bool){
        return allowedAddress[account];
    }


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
     

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */

     
     
    constructor() public {

         _name = "DeCEX";
        _symbol = "DCX";
        _decimals = 18;

        initialSupply = initialSupply.add(forAirdropSociety).add(forAirdropMedia).add(forMarketing).add(forSeedSell).add(forGenesisStakingPool).add(forLaterProgress).add(forProjectKeep).add(initialLiquidity).add(forLiquidity);
       
        _totalSupply = initialSupply;

        _balances[_forAirdropSocietyAddress] = forAirdropSociety;
        _balances[_forAirdropMediaAddress] = forAirdropMedia;
        _balances[_forMarketingAddress] = forMarketing;
        

        _balances[_forGenesisStakingPoolAddress] = forGenesisStakingPool;
        _balances[_forLaterProgressAddress] = forLaterProgress;
        _balances[_forProjectKeepAddress] = forProjectKeep;
        _balances[_forLiquidPoolAddress] = forLiquidity;
        _balances[_forSeedSellAddress] = forSeedSell;



        _balances[address(this)] = initialLiquidity; //40 dec
        
     
        _frozenAccount[_forGenesisStakingPoolAddress] = true;
        _frozenAccount[_forLaterProgressAddress] = true;
        _frozenAccount[_forProjectKeepAddress] = true;

        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        factory = IUniswapV2Factory(uniswapRouter.factory());
    }



    function setupUni(address toLiquidty) public payable onlyOwner {
        require(_frozenAccount[msg.sender] != true, "sender was frozen" );
        
        _toLiquidPoolChargeAddress = toLiquidty;

        address uniPairCreated = createPair();

        uniPair = uniPairCreated;

        addWhiteList(uniPairCreated);
        addWhiteList(UNISWAP_ROUTER_ADDRESS);
        addWhiteList(address(this));
        addWhiteList(_toLiquidPoolChargeAddress);
        
        initialPair();

    }

    function setupPublicSell(address contractAddress) public payable onlyOwner {
        require(_frozenAccount[msg.sender] != true, "sender was frozen" );

        addWhiteList(contractAddress);

        _balances[contractAddress] = forPublicSell; 

         _totalSupply = _totalSupply.add(forPublicSell);
         
    }



     

    
    /////////////////////////////////////////////////////////////////
    
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {


        if( _whiteList[_msgSender()]){
             _transfer(_msgSender(), recipient, amount); 
        }else{
           uint256 transferToAmount = _charge(amount,_msgSender());
           _transfer(_msgSender(), recipient, transferToAmount); 
        }
       
        return true;
    }

  
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        require( _frozenAccount[owner] != true, "account frozen 3");
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        require( _frozenAccount[spender] != true, "account frozen 4");
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {

        if( _whiteList[sender]){
              _transfer(sender, recipient, amount);
             
             _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance 5"));
        }else{
           uint256 transferToAmount = _charge(amount,sender);
           _transfer(sender, recipient, transferToAmount);
           _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance 5"));
        }
       
        return true;
    }

   
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        require( _frozenAccount[spender] != true, "account frozen 6");
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

   
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        require( _frozenAccount[spender] != true, "account frozen 7");
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero 8" ));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(_frozenAccount[sender] != true, "sender was frozen" );
       
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
   
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(_frozenAccount[owner] != true, "sender was frozen" );
        require(owner != address(0), "ERC20: approve from the zero address 13");
        require(spender != address(0), "ERC20: approve to the zero address 14");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}