//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

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

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

contract Swapper is Ownable {

    // swap paths
    address[] private buyPath;
    address[] private sellPath;

    // router
    IUniswapV2Router02 public router;

    // token
    address public immutable token;

    // Fee Information
    uint256 public fee;
    uint256 private constant fee_denom = 10_000;
    address public feeRecipient;

    modifier onlyToken() {
        require(
            msg.sender == token,
            'Only Token'
        );
        _;
    }

    constructor(
        address token_,
        address router_,
        address feeRecipient_
    ) {

        // instantiate router and token
        router = IUniswapV2Router02(router_);
        token = token_;

        // define buy path
        buyPath = new address[](2);
        buyPath[0] = router.WETH();
        buyPath[1] = token_;

        // define sell path
        sellPath = new address[](2);
        sellPath[0] = token_;
        sellPath[1] = router.WETH();

        // Fee Recipient
        feeRecipient = feeRecipient_;
    }

    function setFee(uint256 newFee) external onlyOwner {
        require(
            newFee <= fee_denom / 2,
            'Fee Too High'
        );
        fee = newFee;
    }

    function setFeeRecipient(address newRecipient) external onlyOwner {
        require(
            newRecipient != address(0),
            'Zero Address'
        );
        feeRecipient = newRecipient;
    }

    function buy(address user) external payable onlyToken {
        
        // add fees
        uint etherFee = ( msg.value * fee ) / fee_denom;
        uint remaining = msg.value - etherFee;

        // take fee
        if (etherFee > 0) {
            (bool s,) = payable(feeRecipient).call{value: etherFee}("");
            require(s, 'Ether Transfer Fail');
        }

        // make the swap
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: remaining
        }(1, buyPath, user, block.timestamp + 100);
    }

    function sell(address user) external onlyToken {

        // fetch balance
        uint bal = IERC20(token).balanceOf(address(this));
        
        // approve and swap balance
        IERC20(token).approve(address(router), bal);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            bal, 1, sellPath, address(this), block.timestamp + 100
        );

        // apply fee
        uint256 etherFee = ( address(this).balance * fee ) / fee_denom;
        uint256 remaining = address(this).balance - etherFee;

        // send fee
        if (etherFee > 0) {
            (bool s,) = payable(feeRecipient).call{value: etherFee}("");
            require(s, 'Failure On FeeRecipient ETH Transfer');
        }

        // send rest of balance to user
        (bool s1,) = payable(user).call{value: remaining}("");
        require(s1, 'Failure On User ETH Transfer');
    }

    function getAmountOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256 _amountOut) {
        address _WETH = router.WETH();
        require(
            _tokenIn == _WETH
            || _tokenOut == _WETH,
            "Must have WETH as tokenIn or tokenOut"
        );
        IUniswapV2Pair _pair = IUniswapV2Pair(IUniswapV2Factory(IUniswapV2Router02(router).factory()).getPair(_tokenIn, _tokenOut));
        
        (   uint256 _reserve0,
            uint256 _reserve1,) = _pair.getReserves();

        (   uint256 _reserveIn,
            uint256 _reserveOut) = 
                (_tokenIn == _pair.token0()) 
                    ? (_reserve0, _reserve1)
                    : (_reserve1, _reserve0);

        // Emulating the token transfer to the pool to get the virtual input amount
        uint256 virtualAmountInput = IERC20(_tokenIn).balanceOf(address(_pair)) + _amountIn - _reserveIn;
        
        return _getAmountOut(virtualAmountInput, _reserveIn, _reserveOut);
    }

    function _getAmountOut(
        uint256 _amountIn, 
        uint256 _reserveIn, 
        uint256 _reserveOut
    ) internal view returns (uint256 _amountOut) {
        // Ensure that the input amount is greater than zero
        require(
            _amountIn > 0,
            'Insufficient input amount'
        );
        
        // Ensure that both reserves are greater than zero
        require(
            _reserveIn > 0 
            && _reserveOut > 0,
            'Insufficient liquidity'
        );
        
        // Calculate the input amount with the fee deducted
        uint256 _amountInWithFee = _amountIn * (fee_denom - fee);
        
        // Calculate the numerator of the output amount equation
        uint256 _numerator = _amountInWithFee * _reserveOut;
        
        // Calculate the denominator of the output amount equation
        uint256 _denominator = (_reserveIn * fee_denom) - _amountInWithFee;
        require(
            _denominator > 0,
            'Divide by zero'
        );
        
        // Calculate the output amount based on the input amount and the reserve amounts of the tokens
        return _numerator / _denominator;
    }

    receive() external payable {}
}