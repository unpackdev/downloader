// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;


struct TokenPair{
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        // uint24 fee;
        
        // uint256 amountOut;
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}



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
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}






abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


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




interface IT2SoulSharesSwapData{
     function addItemToSharesTokenList(uint256 sharesSubject, TokenPair calldata item) external returns(bool );
     function getSharesTokenListByShares(uint256 sharesSubject) external view returns (TokenPair[] memory);
     function removeSharesTokenByIdPair(uint256 sharesSubject, address pairTokenIn,address pairTokenOut) external  returns (bool);
     function getTokenPairBalance(uint256 sharesSubject,address tokenIn,address tokenOut) external view  returns(uint256 tokenBalance);
     /**
     * 
     * @param sharesSubject subject
     * @param tokenIn  token1 addr
     * @param tokenOut token2 addr 
     * @param amount   amout unit wei
     * @param plusflag true:plus,false:sub
     */
     function setTokenPairBlance(uint256 sharesSubject,address tokenIn,address tokenOut,uint256 amount,bool plusflag) external returns(bool );
      

}


interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}



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
/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}



library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}



interface IVerifySig{
   

    /**
     * 
     * @param claimer  sender
     * @param questWallet  quest's wallet
     * @param questId  questid
     * @param _signature  sigstr
     * @return signer_ wallet
     * @return resMsg_ 
     */   
    function isT2MsgValid(address claimer,address questWallet, uint256 questId,bytes memory _signature) external view returns (address signer_, string memory resMsg_); 
}

contract Utilities is Ownable, Pausable {

 mapping(address => bool) private admins;

    function addAdmin(address _address) public virtual onlyOwner {
        // require(_address.code.length>0," must be a contract's address");
        admins[_address] = true;
    }

    function addAdmins(address[] calldata _addresses) public virtual onlyOwner {
        uint256 len = _addresses.length;
        for (uint256 i = 0; i < len; i++) {
            // require(_addresses[i].code.length>0," must be a contract's address");
            admins[_addresses[i]] = true;
        }
    }

    // function addAdminsInternal(address[] calldata _addresses) internal {
    //     uint256 len = _addresses.length;
    //     for(uint256 i=0;i<len;i++)
    //     {
    //         // require(_addresses[i].code.length>0," must be a contract's address");
    //         admins[_addresses[i]]=true;
    //     }
    // }

    function removeAdmin(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function removeAdmin(address[] calldata _addresses) external onlyOwner {
        uint256 len = _addresses.length;
        for (uint256 i = 0; i < len; i++) {
            admins[_addresses[i]] = false;
        }
    }

    // function removeAdminInternal(
    //     address[] memory _addresses
    // ) internal onlyOwner {
    //     uint256 len = _addresses.length;
    //     for (uint256 i = 0; i < len; i++) {
    //         admins[_addresses[i]] = false;
    //     }
    // }

    function setPause(bool _shouldPause) external onlyAdminOrOwner {
        if (_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function isAdmin(address _address) public view returns (bool) {
        return admins[_address];
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(admins[msg.sender] || isOwner(), "Not admin or owner");
        _;
    }
    // modifier nonZeroAddress(address _address)    {
    //     require(address(0) != _address, "0 address");
    //     _;
    // }
    // modifier nonZeroLength(uint[] memory _array) {
    //     require(_array.length > 0, "Empty array");
    //     _;
    // }
    // modifier lengthsAreEqual(uint[] memory _array1, uint[] memory _array2) {
    //     require(_array1.length == _array2.length, "Unequal lengths");
    //     _;
    // }
    modifier onlyEOA() {
        /* solhint-disable avoid-tx-origin */
        require(msg.sender == tx.origin, "No contracts");
        _;
    }

    modifier sharesCaller() {
        /* solhint-disable avoid-tx-origin */
        require(msg.sender == tx.origin||isAdmin(msg.sender), " caller address error ");
        _;
    }

    function isOwner() internal view returns (bool) {
        return owner() == msg.sender;
    }

//     function isContract(address addr) internal view returns (bool) {
//         uint256 size;
//         assembly { size := extcodesize(addr) }
//         return size > 0;
//   }
}


contract T2SoulSharesFinance is Utilities {
    // Import SafeMath library for uint256
    using SafeMath for uint256;   
    address public  swapRouteV3Addr;
    address public  swapRouteV2Addr;

    address public protocolFeeDestination=0x2dFd4225De01DD83Da644285D07Fe2A43A5cEa62;

    //k-6:official-4,10000000000000000:10000000000000000,k+o=2%
    uint256 private  protocolFeePercent = 0.01 ether;
    uint256 private  subjectFeePercent = 0.01 ether;
    
    //perUnitValue lessthan 1: 10% feed
    // uint256 public lessOneBseFeePercent = 0.1 ether;
    //perUnitValue lessthan 1: 2% feed send to protocol&subjectfeepercent
    uint256 private  lessOneProtocolFeePercent = 0.02 ether;
    //perUnitValue lessthan 1: 8% feed  send to sharespool,lessOneBseFeePercent eq sum(lessOneProtocolFeePercent,lessOneSharesPoolFeePercent)
    uint256 private  lessOneSharesPoolFeePercent = 0.08 ether;

    //init shares price 10000000000000000
    uint256 public basePrice =0.01 ether;
        

    //Verify contract's addressqiang
    address private verifySigAddr;
    //signature's address
    address private t2t2SignatureAddr;    
  
    address public WETHAddr;   
    address public  t2swapDataAddr;  
  
    // SharesSubject => (Holder => Balance)
    mapping(uint256 => mapping(address => uint256)) public sharesBalance;

    // SharesSubject => Supply
    mapping(uint256 => uint256) public sharesSupply;
    mapping(address => uint256) private addr2RoomIdMap;
    mapping(uint256 => address) private roomId2AddrMap;
    //房主费
    mapping(uint256 => uint256) public masterFeeBalance;
    //subject =>amount unitValue lessOne balance reward pool
    mapping(uint256=>uint256) public sharesPool;
    //每个房间的eth余额
    mapping(uint256=>uint256) public roomEthBalance;   
    //30 sec
    uint24 public deadLineSec=30;

   

    // totoalpoolAmout:8%奖金池,totoalpoolAmout:8%奖金池总额
    event Trade(address trader, uint256 subject,bool isBuy,uint256 shareAmount,uint256 ethAmount,uint256 protocolEthAmount,uint256 subjectEthAmount,uint256 supply,uint256 poolAmount,uint256 poolTotalAmount);    
    //is_buy, totalAmount, changeAmount, tx_hash, created_at 
    //tradeType 0:key交易，1.token交易
    event SharesETHChange(uint256 subject, uint tradeType,  bool isBuy,uint256 changeAmount);
    event Deposit(address indexed from, uint256 amount);
    event Withdraw(address indexed from, uint256 amount);  
   
    //tokenBalance:token余额，sharesSubjectEthBalance：房间eth余额，isBuy --true: 投资eth兑换token，false:token 兑换eth
    event ExcutSwapSingle(uint256 sharesSubject,address sender, bool isBuy, address tokenIn,uint256 tokenInAmout, address tokenOut,uint256 tokenOutAmout,uint24 swapfeed,address receiver);

    event ExcutSwapMulti(uint256 sharesSubject, address sender,address[] tokenIns,uint24[]  fees, address tokenOut,uint256 tokenOutAmout,address receiver);


    constructor()
    {}


    function setUniSwapAddr(address uniV2RouterAddr_,address uniV3RouterAddr_) external onlyAdminOrOwner  returns (bool)
    {
        require(uniV2RouterAddr_!= address(0) && uniV3RouterAddr_!= address(0)," set uniVRouter error");
        swapRouteV2Addr = uniV2RouterAddr_;      
        swapRouteV3Addr = uniV3RouterAddr_;
        return true;

    }


   function setContracts(address verifySigAddr_, address t2t2SigAddr_,address  t2swapDataAddr_,address weth_) external onlyAdminOrOwner  returns (bool) {
        require(verifySigAddr_ != address(0) && t2t2SigAddr_ != address(0) && t2swapDataAddr_!=address(0) && weth_ != address(0) ,"set contracts error" ); 
        verifySigAddr = verifySigAddr_;
        t2t2SignatureAddr = t2t2SigAddr_;   
         WETHAddr = weth_;   
        t2swapDataAddr = t2swapDataAddr_;              
        return true;
    }

    function setBasePrice(uint256 _basePrice) public onlyAdminOrOwner {
        basePrice = _basePrice;
    }

     function setDeadLine(uint24 _deadLine) public onlyAdminOrOwner {
        
        deadLineSec = _deadLine;
    }


    function setFeesInfor(uint256 _protocolFee,uint256 _subjectFee,uint256 _lessOneProtocolFee,uint256 _lessOneSharesPoolFee) public onlyAdminOrOwner {
        protocolFeePercent = _protocolFee;
        subjectFeePercent = _subjectFee;
        lessOneProtocolFeePercent = _lessOneProtocolFee;
        lessOneSharesPoolFeePercent = _lessOneSharesPoolFee;
    }

    function getFeesInfor() public view returns (uint256 _protocolFee,uint256 _subjectFee,uint256 _lessOneProtocolFee,uint256 _lessOneSharesPoolFee)
    {
        
        _protocolFee= protocolFeePercent;
        _subjectFee=subjectFeePercent;
        _lessOneProtocolFee= lessOneProtocolFeePercent ;
        _lessOneSharesPoolFee=lessOneSharesPoolFeePercent ;
    }

    function setFeeDestination(
        address _feeDestination
    ) public onlyAdminOrOwner {
        require(address(0)!=_feeDestination," addr error");
        protocolFeeDestination = _feeDestination;
    }

     
    function getSharesTokenListByShares(uint256 sharesSubject) public view returns (TokenPair[] memory) {
        return  IT2SoulSharesSwapData(t2swapDataAddr).getSharesTokenListByShares(sharesSubject);
    }

    function getTokenPairBalance(uint256 sharesSubject,address tokenIn,address tokenOut) public view  returns(uint256 tokenBalance){
      
        return  IT2SoulSharesSwapData(t2swapDataAddr).getTokenPairBalance(sharesSubject,tokenIn,tokenOut);

    }  

    function getSwapAmountArry(uint amountIn, address[] memory  paths) public view  returns(uint[] memory amountOut)
    {
         amountOut = IUniswapV2Router02(swapRouteV2Addr).getAmountsOut(amountIn,paths);
         return amountOut;
    }

    function getSwapAmount(uint amountIn,address  tokenIn,address  tokenOut) public view  returns(uint[] memory amountOut)
    {       
        address[] memory paths = new address[](2);
        paths[0] = tokenIn;
        paths[1] = tokenOut;              
        amountOut = IUniswapV2Router02(swapRouteV2Addr).getAmountsOut(amountIn,paths);
        return amountOut;
    }
   

    function getPrice(uint256 supply,uint256 amount) public view returns (uint256) {
        uint256 sum1 = supply == 0? 0: ((supply - 1) * (supply) * (2 * (supply - 1) + 1)) / 6;
        uint256 sum2 = supply == 0 && amount == 1? 0: ((supply - 1 + amount) *(supply + amount) * (2 * (supply - 1 + amount) + 1)) / 6;
        uint256 summation = sum2 - sum1;
        uint256 basePrice_ = basePrice.mul(amount);
        return basePrice_>0?basePrice_.add((summation * 1 ether) / 16000):((summation * 1 ether) / 16000);
        // return  basePrice.add((summation * 1 ether) / 16000);
    }

    function getBuyPrice(uint256 sharesSubject,uint256 amount
    ) public view returns (uint256) {
        return getPrice(sharesSupply[sharesSubject], amount);
    }

    function getSellPrice(uint256 sharesSubject,uint256 amount) public view returns (uint256) {
        return getPrice(sharesSupply[sharesSubject] - amount, amount);
    }

    function getBuyPriceAfterFee(uint256 sharesSubject,uint256 amount) public view returns (uint256) {
        uint256 price = getBuyPrice(sharesSubject, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1 ether;
        uint256 subjectFee = (price * subjectFeePercent) / 1 ether;
        return price + protocolFee + subjectFee;
    }

    function getSellPriceAfterFee(
        uint256 sharesSubject,
        uint256 amount
    ) public view returns (uint256) {
        uint256 price = getSellPrice(sharesSubject, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1 ether;
        uint256 subjectFee = (price * subjectFeePercent) / 1 ether;
        return price - protocolFee - subjectFee;
    }

    //基金份额
  

    function getSharesTotalAmount(uint256 sharesSubject) public view returns(uint256 )
    {
        uint256 supply = sharesSupply[sharesSubject];
        if(supply==0)
        {
          return 0;
        }
        else{
            uint256 sumFundShareAmount =0;
            for (uint32 i = 0; i <supply; i++) {
                sumFundShareAmount = sumFundShareAmount+getPrice(i,1);
            }
            return sumFundShareAmount;
        }
    }


    
 
    function buyShares(uint256 sharesSubject, uint256 amount) public payable sharesCaller {

        uint256 supply = sharesSupply[sharesSubject];
        // require(
        //     supply > 0 || sharesSubject == msg.sender,
        //     "Only the shares' subject can buy the first share"
        // );
        require(supply > 0, "Unable to buy sharesSubject don't running");
        buyInterShares(sharesSubject, amount, supply);
    }

    function getETHProfit(uint256 sharesSubject, uint256 sellRatio) public view returns(bool existToken_,uint256 swapWETHTotalAmout_, TokenPair[] memory sellPairs_){
        existToken_= false;
        swapWETHTotalAmout_ =0;
        uint256 sharesTokenBalance =0;
        uint256 swapAmoutInTemp =0;       
        uint256 i =0;
        uint256[] memory amoutOut;

         TokenPair[] memory tokenPairs = IT2SoulSharesSwapData(t2swapDataAddr).getSharesTokenListByShares(sharesSubject);
         if(tokenPairs.length==0)
         {
            return(false,0,sellPairs_); 
         } 
        sellPairs_=  new TokenPair[](tokenPairs.length);
        for (uint128 index = 0; index < tokenPairs.length; index++) {
          sharesTokenBalance=  IT2SoulSharesSwapData(t2swapDataAddr).getTokenPairBalance(sharesSubject,tokenPairs[index].tokenIn,tokenPairs[index].tokenOut);
          if(sharesTokenBalance>0)
          {
              existToken_ = true;
              //sell Amount
              swapAmoutInTemp = (sharesTokenBalance.mul(sellRatio))/1 ether;
              TokenPair memory item = TokenPair(tokenPairs[index].tokenOut, tokenPairs[index].tokenIn,swapAmoutInTemp);
              sellPairs_[i]=item;
              i = i+1;
              address[] memory paths = new address[](2);
              paths[0] = tokenPairs[index].tokenOut;
              paths[1] = tokenPairs[index].tokenIn;               
              amoutOut = IUniswapV2Router02(swapRouteV2Addr).getAmountsOut(sharesTokenBalance,paths);
              //weth收益总收益量
              swapWETHTotalAmout_ = swapWETHTotalAmout_.add(amoutOut[0]);
          }
        }

        return(existToken_,swapWETHTotalAmout_,sellPairs_);

    }


    function emitExcutSwapSingle(uint256 sharesSubject, bool isBuy, address tokenIn,uint256 tokenInAmout, address tokenOut,uint256 tokenOutAmout,uint24 swapfeed) internal {
        emit ExcutSwapSingle(sharesSubject,msg.sender,isBuy,tokenIn,tokenInAmout,tokenOut,tokenOutAmout,swapfeed,address(this));             
    }

    function getSellRatio(uint256 sharesSubject, uint256 price) public view returns (uint256 ratio)
    {
        ratio = 1;
        uint256 sharesTotalAmout =   getSharesTotalAmount(sharesSubject);
        if(sharesTotalAmout==0)
        {
            return ratio;
        }else 
        {
           //using div 1 ether
            ratio = price.mul(1 ether).div(sharesTotalAmout);
            return ratio;     
        }
        
    } 

    
    //清算资产
    function sellAssetToken(uint256 sharesSubject,uint256 price,uint24 swapFee) internal returns(uint256 price_ ) {

        bool existToken_ = false;  
        price_ =0;
        // perUnitValue_=1;
        // uint256 sharesTotalAmout =   getSharesTotalAmount(sharesSubject);
        uint256 sellRatio = getSellRatio(sharesSubject,price);// price.mul(1 ether).div(sharesTotalAmout);
        TokenPair[] memory sellPairs; 
        uint256  swapWETHTotalAmout =0; 
        uint256 swapAmoutInTemp =0;
        (existToken_,swapWETHTotalAmout,sellPairs)=getETHProfit(sharesSubject,sellRatio);

         //只存在eth
        if(existToken_==false)
        {
            // uint256 re =roomEthBalance[sharesSubject];
            //单位净值            
            // perUnitValue_  =re.div(sharesTotalAmout)/ 1 ether;
            price_ = (sellRatio.mul(roomEthBalance[sharesSubject]))/1 ether; 
            require(roomEthBalance[sharesSubject]>=price_," price balance error");
            roomEthBalance[sharesSubject] = roomEthBalance[sharesSubject].sub(price_);        
            emit SharesETHChange(sharesSubject,0,false,price_);

        }

        if(existToken_==true)
        {          
           uint256 swapToken2WETH =0; 
        //    uint256 re =0;
           for (uint128 index = 0; index < sellPairs.length; index++) {             
                   IT2SoulSharesSwapData(t2swapDataAddr).setTokenPairBlance(sharesSubject,sellPairs[index].tokenOut,sellPairs[index].tokenIn,sellPairs[index].amountIn,false);                                 
                   TransferHelper.safeApprove(sellPairs[index].tokenIn, swapRouteV3Addr, sellPairs[index].amountIn);  
                   swapAmoutInTemp =swapSingle(sellPairs[index].tokenIn,sellPairs[index].tokenOut,sellPairs[index].amountIn,swapFee,address(this)); 
                   swapToken2WETH = swapToken2WETH.add(swapAmoutInTemp);          
                   emitExcutSwapSingle(sharesSubject,false,sellPairs[index].tokenIn,sellPairs[index].amountIn, sellPairs[index].tokenOut,swapAmoutInTemp,swapFee);
               }          
            IWETH(WETHAddr).withdraw(swapToken2WETH);               
           //只存在token
            if(roomEthBalance[sharesSubject]==0)
            {   
                //swapWETHTotalAmout 总净资产              
                // perUnitValue_  =swapWETHTotalAmout.div(sharesTotalAmout)/ 1 ether;                       
                price_=swapToken2WETH;
            }else if(roomEthBalance[sharesSubject]>0 )
            {  //存在eth和token                
                //清算房间eth 
                swapAmoutInTemp= roomEthBalance[sharesSubject].mul(sellRatio)/1 ether;
                require(roomEthBalance[sharesSubject]>=swapAmoutInTemp," roomEthBalance  error");
                //房间总价值
                swapWETHTotalAmout =swapWETHTotalAmout.add(roomEthBalance[sharesSubject]);
                // perUnitValue_  =swapWETHTotalAmout.div(sharesTotalAmout)/1 ether;               
                roomEthBalance[sharesSubject]=roomEthBalance[sharesSubject].sub(swapAmoutInTemp); 
                emit SharesETHChange(sharesSubject,0,false,swapAmoutInTemp);
                price_ = swapToken2WETH.add(swapAmoutInTemp);
            }
        }
        
        return price_;

    }

    function sellShares(uint256 sharesSubject, uint256 amount,uint24 swapFee) public payable sharesCaller {
      
        uint256 supply = sharesSupply[sharesSubject];
        require(supply > amount, "Cannot sell the last share");
        require(sharesBalance[sharesSubject][msg.sender] >= amount,"Insufficient shares amount ");
       

        uint256 price = getPrice(supply- amount, amount);
        //使用时在除以 1 ether 5343750000000000
        // uint256 sellRatio = price.mul(1 ether).div(sharesTotalAmout);
        //计算价格占比
        //清算token 1.只有ETH，2.只有有token token，3.有eth&token      
        // uint256 sharesTokenBalance =0;
        uint256 perUnitValue=1;  
        //总收益
        (,perUnitValue,)=getETHProfit(sharesSubject,getSellRatio(sharesSubject,price));
      
        perUnitValue = perUnitValue.add(roomEthBalance[sharesSubject]); 
      
        //净值
        perUnitValue = (perUnitValue.mul(1 ether)).div(getSharesTotalAmount(sharesSubject))/ 1 ether; 
        
        price=  sellAssetToken(sharesSubject,price,swapFee);
     
        uint256 protocolFee=0;
        uint256 subjectFee=0;
        uint256 lessOneSharesFundPoolFee=0;
        if(perUnitValue>=1)
        {
            protocolFee = (price * protocolFeePercent) / 1 ether;
            subjectFee = (price * subjectFeePercent) / 1 ether;
        }else if(perUnitValue<1)
        {      
           protocolFee=subjectFee =((price * lessOneProtocolFeePercent) / 1 ether).div(2);
           lessOneSharesFundPoolFee = (price * lessOneSharesPoolFeePercent) / 1 ether;
             
        }
   
        sharesBalance[sharesSubject][msg.sender] =sharesBalance[sharesSubject][msg.sender] - amount;
        sharesSupply[sharesSubject] = sharesSupply[sharesSubject] - amount;      
     
        // uint256 getValue = price - protocolFee - subjectFee;
        if(perUnitValue>=1)
        {
            (bool success1, ) = msg.sender.call{value:  (price - protocolFee - subjectFee)}("");
            (bool success2, ) = protocolFeeDestination.call{value: protocolFee}("");

            // (bool success3, ) = sharesSubject.call{value: subjectFee}("");
            //   require(success1 && success2 && success3, "Unable to send funds");
            masterFeeBalance[sharesSubject] = masterFeeBalance[sharesSubject].add(subjectFee);
            require(success1 && success2, "Unable to sell send funds");
        }else if(perUnitValue<1)
        {
            (bool success1, ) = msg.sender.call{value:  (price - protocolFee - subjectFee)}("");
            (bool success2, ) = protocolFeeDestination.call{value: protocolFee}("");
            masterFeeBalance[sharesSubject] = masterFeeBalance[sharesSubject].add(subjectFee);
            sharesPool[sharesSubject] =sharesPool[sharesSubject].add(lessOneSharesFundPoolFee);
            require(success1 && success2, "Unable to sell pool send funds");
        }
        // uint256 pools = sharesPool[sharesSubject];
        perUnitValue = sharesPool[sharesSubject];
        supply= supply- amount;
        emitTrader(msg.sender,sharesSubject,false,amount,price,protocolFee,subjectFee,supply,lessOneSharesFundPoolFee, perUnitValue);


    }

    function buyInterShares(uint256 sharesSubject,uint256 amount,uint256 supply) internal {
        // uint256 supply = sharesSupply[sharesSubject];       
        uint256 price = getPrice(supply, amount);
        uint256 protocolFee = (price * protocolFeePercent) / 1 ether;
        uint256 subjectFee = (price * subjectFeePercent) / 1 ether;    
        require(msg.value >= price + protocolFee + subjectFee,"Insufficient payment");
        sharesBalance[sharesSubject][msg.sender] =sharesBalance[sharesSubject][msg.sender] + amount;
        sharesSupply[sharesSubject] = supply + amount;        
        uint256 balanceValue = msg.value.sub(protocolFee);
        balanceValue = balanceValue.sub(subjectFee);

        roomEthBalance[sharesSubject]=roomEthBalance[sharesSubject].add(balanceValue);
        emit SharesETHChange(sharesSubject,0,true,balanceValue);
        uint256 swapWETHTotalAmout =0;
     
        //份额
        uint256 sharesTotalAmout =   getSharesTotalAmount(sharesSubject);
        uint256 sellRatio = getSellRatio(sharesSubject,price);// price.mul(1 ether).div(sharesTotalAmout);      
        (,swapWETHTotalAmout,)=getETHProfit(sharesSubject,sellRatio);
        swapWETHTotalAmout = swapWETHTotalAmout.add(roomEthBalance[sharesSubject]);           
        if(supply>0)
        {
            //净值
            sharesTotalAmout  =swapWETHTotalAmout.div(sharesTotalAmout)/ 1 ether;  
        }
        masterFeeBalance[sharesSubject] = masterFeeBalance[sharesSubject].add(subjectFee);   
        (bool success1, ) = protocolFeeDestination.call{value: protocolFee}("");      
        sellRatio=0;   
        if (sharesTotalAmout<1)
        {
           if(sharesPool[sharesSubject]>0) 
           {
                sellRatio = sharesPool[sharesSubject];
                sharesPool[sharesSubject]=0;        
                (bool success2, ) = msg.sender.call{value: sellRatio}(""); 
                require(success1 && success2, " Unable buy to send pool funds");
           }else
           {
             require(success1, " protocolFee 1 error ");
           }
        }else 
        {
            require(success1, " protocolFee 2 error");
        }
        // (bool success2, ) = sharesSubject.call{value: subjectFee}("");
        // require(success1 && success2, "Unable to send funds");
        // sharesTotalAmout ==sellRatio
        sharesTotalAmout = sharesSupply[sharesSubject];     
        balanceValue   =sharesPool[sharesSubject];
        //sellRatio 代表冒险基金
        emitTrader(msg.sender,sharesSubject,true, amount,price,protocolFee,subjectFee,sharesTotalAmout,sellRatio, balanceValue);
        
        
        
    }
   
     function emitTrader(address trader, uint256 subject,bool isBuy,uint256 shareAmount,uint256 ethAmount,uint256 protocolEthAmount,uint256 subjectEthAmount,uint256 supply,uint256 poolAmount,uint256 poolTotalAmount) internal {
         emit Trade(trader,subject,isBuy, shareAmount,ethAmount,protocolEthAmount,subjectEthAmount,supply,poolAmount,poolTotalAmount);
     }


    // function bindRoomTest(uint256 sharesSubject) payable external  returns (bool) {
    
    //     address addr_ = tx.origin;
    //     uint256 supply = sharesSupply[sharesSubject];
    //     if (supply == 0) {
    //         buyInterShares(sharesSubject, 1, supply);
    //     }

    //     if (roomId2AddrMap[sharesSubject] != address(0)) {
    //         delete addr2RoomIdMap[roomId2AddrMap[sharesSubject]];
    //         delete roomId2AddrMap[sharesSubject];
    //     }
    //     roomId2AddrMap[sharesSubject] = addr_;
    //     addr2RoomIdMap[addr_] = sharesSubject;
    //     return true;
    // }

    function bindRoomAddr(uint256 sharesSubject,bytes memory _signature) payable external sharesCaller whenNotPaused returns (bool) {
        
     
        require(verifySinger(sharesSubject, _signature), " singer error");
        address addr_ = tx.origin;
        uint256 supply = sharesSupply[sharesSubject];
        if (supply == 0) {
            buyInterShares(sharesSubject, 1, supply);
        }

        if (roomId2AddrMap[sharesSubject] != address(0)) {
            delete addr2RoomIdMap[roomId2AddrMap[sharesSubject]];
            delete roomId2AddrMap[sharesSubject];
        }
        roomId2AddrMap[sharesSubject] = addr_;
        addr2RoomIdMap[addr_] = sharesSubject;
        return true;
    }

    function getBindRoomAddr( uint256 roomId ) public view  returns (address addr) {
        return roomId2AddrMap[roomId];
    }

    fallback() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function verifySinger( uint256 roomId, bytes memory _signature ) internal view returns (bool) {
        IVerifySig verifySig = IVerifySig(verifySigAddr);
        string memory sigStr = "";
        address sig_;        
        (sig_, sigStr) = verifySig.isT2MsgValid(tx.origin, t2t2SignatureAddr,roomId, _signature );       
        if (sig_ == t2t2SignatureAddr) {
            return true;
        } else {
            return false;
        }
    }

    function withdraw(uint256 sharesSubject) external {
        address to = roomId2AddrMap[sharesSubject];
        uint256 amount_ = masterFeeBalance[sharesSubject];
        require(msg.sender == to," room's address or sender's address is error");
        require(amount_ > 0, " shaers key amount error");
        masterFeeBalance[sharesSubject] = 0;
        uint256 amount = address(this).balance;
        require(amount >= amount_, " withdraw amount error! ");
        payable(to).transfer(amount_);
        emit Withdraw(to, amount_);
    }

    //swap
    function ethApproveSwap(uint256 amountIn) public {         
        IWETH(WETHAddr).deposit{value: amountIn}();
        IWETH(WETHAddr).approve(swapRouteV3Addr, amountIn);  
    }

    //token 兑换eth
    function sellToken(uint256 sharesSubject,address tokenIn,address tokenOut,uint256 amountIn,uint24 swapFee) public  sharesCaller
    {   
        
          
        uint256 tokenBalance =  IT2SoulSharesSwapData(t2swapDataAddr).getTokenPairBalance(sharesSubject,tokenIn,tokenOut);  
        require(tokenBalance>=amountIn && amountIn>0 ," amountIn error ");       
        require(msg.sender ==  roomId2AddrMap[sharesSubject]," room's address or sender's address is error");         
        require(tokenIn!=address(0) && tokenOut!=address(0) && swapFee>0," pairs error");         
        address receiver = address(this);
        // 
        TransferHelper.safeApprove(tokenIn, swapRouteV3Addr, amountIn);  
        IT2SoulSharesSwapData(t2swapDataAddr).setTokenPairBlance(sharesSubject,tokenIn,tokenOut,amountIn,false); 
        uint256 tokenAmontOut = swapSingle(tokenIn,tokenOut,amountIn,swapFee,receiver);      
        IWETH(WETHAddr).withdraw(tokenAmontOut);         
        roomEthBalance[sharesSubject]=roomEthBalance[sharesSubject].add(tokenAmontOut);  
        emit SharesETHChange(sharesSubject,1,false,tokenAmontOut);    
        emit ExcutSwapSingle(sharesSubject,msg.sender,false,tokenIn,amountIn,tokenOut,tokenAmontOut,swapFee,receiver); 

    }

    //front call eth->token
    function excuteBuySingle(uint256 sharesSubject,address tokenIn,address tokenOut,uint256 amountIn,uint24 swapFee)  public sharesCaller payable  {
       
        require(address(tokenIn)==address(WETHAddr) ," tokenIn address error"); 
        require(tokenIn!=address(0) && tokenOut!=address(0)," token address error");
        require(amountIn>0 ," amountIn error");       
        require(roomEthBalance[sharesSubject]>=amountIn, " room's eth amount error");
        require(msg.sender ==  roomId2AddrMap[sharesSubject]," room's address or sender's address is error");         
        require(tokenIn!=address(0) && tokenOut!=address(0) && swapFee>0," pairs error");    

        roomEthBalance[sharesSubject]=roomEthBalance[sharesSubject].sub(amountIn);  
        emit SharesETHChange(sharesSubject,1,true,amountIn);          
        IWETH(WETHAddr).deposit{value: amountIn}();
        TransferHelper.safeApprove(tokenIn, swapRouteV3Addr, amountIn);        
        address receiver =address(this);             
          // pool swapFee 0.3%
        // ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
        //     { tokenIn: tokenIn,tokenOut: tokenOut,fee: swapFee,recipient: receiver,deadline: block.timestamp+deadLineSec,amountIn: amountIn,amountOutMinimum: 0,
        //     // NOTE: In production, this value can be used to set the limit
        //     // for the price the swap will push the pool to,
        //     // which can help protect against price impact
        //     sqrtPriceLimitX96: 0
        // });
        uint256 amountOut =swapSingle(tokenIn,tokenOut,amountIn,swapFee,receiver); 
        //添加每个房间的数量   addItemToSharesTokenList(uint256 sharesSubject, TokenPair calldata item) 
        TokenPair memory item = TokenPair(tokenIn,tokenOut,amountIn);  
        IT2SoulSharesSwapData(t2swapDataAddr).addItemToSharesTokenList(sharesSubject,item);     
        IT2SoulSharesSwapData(t2swapDataAddr).setTokenPairBlance(sharesSubject,tokenIn,tokenOut,amountOut,true);          
        emit ExcutSwapSingle(sharesSubject,msg.sender,true,tokenIn,amountIn,tokenOut,amountOut,swapFee,receiver);       
        
    }

     function swapSingle(address tokenIn,address tokenOut,uint256 amountIn,uint24 swapFee,address receiver)  internal returns(uint256 amountOut)   {

     
           // pool swapFee 0.3%
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            { tokenIn: tokenIn,tokenOut: tokenOut,fee: swapFee,recipient: receiver,deadline: block.timestamp+deadLineSec,amountIn: amountIn,amountOutMinimum: 0,
            // NOTE: In production, this value can be used to set the limit
            // for the price the swap will push the pool to,
            // which can help protect against price impact
            sqrtPriceLimitX96: 0
        });
        amountOut = ISwapRouter(swapRouteV3Addr).exactInputSingle(params);
        return amountOut;

     }


     

    // function excuteBuyMulti(uint256 sharesSubject,address[] calldata tokenIns,uint24[] calldata fees,address tokenOut,uint256 amountIn) external sharesCaller{
       
  
    //     require(amountIn>0 ," amountIn error");       
    //     require(roomEthBalance[sharesSubject]>=amountIn, " room's eth amount error");
    //     require(msg.sender ==  roomId2AddrMap[sharesSubject]," room's address or sender's address is error");                        
       
    //     uint256 tokenLen =tokenIns.length;
    //     address receiver =address(this);
    //     bytes memory paths;
    //     require(tokenLen>=2 && tokenLen<=4 && tokenLen==fees.length," excuteMulti params numberic error");
    //     for (uint24 index = 0; index < tokenLen; index++) {
    //         require(tokenIns[index]!=address(0) && fees[index]>0," excuteMulti pairs element error");
    //     }

    //     roomEthBalance[sharesSubject]=roomEthBalance[sharesSubject].sub(amountIn);     //  
    //     emit SharesETHChange(sharesSubject,1,true,amountIn,re);  
    //     IWETH(WETHAddr).deposit{value: amountIn}();
    //     TransferHelper.safeApprove(tokenIns[0], swapRouteV3Addr, amountIn); 

    //     if(tokenLen==2)
    //     {
    //         paths =abi.encodePacked(tokenIns[0],uint24(fees[0]),tokenIns[1],uint24(fees[1]),tokenOut);
    //     }else if(tokenLen==3)
    //     {
    //         paths =abi.encodePacked(tokenIns[0],uint24(fees[0]),tokenIns[1],uint24(fees[1]),tokenIns[2],uint24(fees[2]),tokenOut);
    //     }else if(tokenLen==4)
    //     {
    //         paths =abi.encodePacked(tokenIns[0],uint24(fees[0]),tokenIns[1],uint24(fees[1]),tokenIns[2],uint24(fees[2]),tokenIns[3],uint24(fees[3]),tokenOut);
    //     }
       
    //     // ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams(
    //     //     {   path:paths,recipient: receiver, deadline: block.timestamp+deadLineSec, amountIn: amountIn,amountOutMinimum: 0 });
    //     // uint256 amountOut = swapRouter.exactInput(params);  
    //     uint256 amountOut =swapMultil(paths,amountIn,receiver);
    //       //添加每个房间的数量
    //     TokenPair memory item = TokenPair(tokenIns[0],tokenOut,amountIn);  
    //     IT2SoulSharesSwapData(t2swapDataAddr).addItemToSharesTokenList(sharesSubject,item);     
    //     IT2SoulSharesSwapData(t2swapDataAddr).setTokenPairBlance(sharesSubject,tokenIns[0],tokenOut,amountOut,true); 
    
    //     emit ExcutSwapMulti(sharesSubject, msg.sender,tokenIns,fees,tokenOut,amountOut,receiver);        
    // }

    // function swapMultil(bytes memory paths,uint256 amountIn,address receiver)  internal returns(uint256 amountOut){
    //      ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams(
    //         {   path:paths,recipient: receiver, deadline: block.timestamp+deadLineSec, amountIn: amountIn,amountOutMinimum: 0 });
    //      amountOut = ISwapRouter(swapRouteV3Addr).exactInput(params);  
    //      return amountOut; 

    // }
}