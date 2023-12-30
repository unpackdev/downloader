// SPDX-License-Identifier: GPL-3.0-or-later

/**
Author: CoFiX Core
*/

pragma solidity ^0.6.6;


// 
interface ICoFiXFactory {
    // All pairs: {ETH <-> ERC20 Token}
    event PairCreated(address indexed token, address pair, uint256);

    /// @dev Create a new token pair for trading
    /// @param  token the address of token to trade
    /// @return pair the address of new token pair
    function createPair(
        address token
        )
        external
        returns (address pair);

    function getPair(address token) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);

    function setGovernance(address _new) external;
    function setController(address _new) external;
    function setFeeReceiver(address _new) external;
    function getController() external view returns (address controller);
    function getFeeReceiver() external view returns (address feeReceiver);
}

// 
// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// 
interface ICoFiXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    // All pairs: {ETH <-> ERC20 Token}

    /// @dev Maker add liquidity to pool, get pool token (mint XToken to maker) (notice: msg.value = amountETH + oracle fee)
    /// @param  token The address of ERC20 Token
    /// @param  amountETH The amount of ETH added to pool
    /// @param  amountToken The amount of Token added to pool
    /// @param  liquidityMin The minimum liquidity maker wanted
    /// @param  to The target address receiving the liquidity pool (XToken)
    /// @param  deadline The dealine of this request
    /// @return liquidity The real liquidity or XToken minted from pool
    function addLiquidity(
        address token,
        uint amountETH,
        uint amountToken,
        uint liquidityMin,
        address to,
        uint deadline
    ) external payable returns (uint liquidity);

    /// @dev Maker remove liquidity from pool to get ERC20 Token back (maker burn XToken) (notice: msg.value = oracle fee)
    /// @param  token The address of ERC20 Token
    /// @param  liquidity The amount of liquidity (XToken) sent to pool, or the liquidity to remove
    /// @param  amountTokenMin The minimum amount of Token wanted to get from pool
    /// @param  to The target address receiving the Token
    /// @param  deadline The dealine of this request
    /// @return amountToken The real amount of Token transferred from the pool
    function removeLiquidityGetToken(
        address token,
        uint liquidity,
        uint amountTokenMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken);

    /// @dev Maker remove liquidity from pool to get ETH back (maker burn XToken) (notice: msg.value = oracle fee)
    /// @param  token The address of ERC20 Token
    /// @param  liquidity The amount of liquidity (XToken) sent to pool, or the liquidity to remove
    /// @param  amountETHMin The minimum amount of ETH wanted to get from pool
    /// @param  to The target address receiving the ETH
    /// @param  deadline The dealine of this request
    /// @return amountETH The real amount of ETH transferred from the pool
    function removeLiquidityGetETH(
        address token,
        uint liquidity,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountETH);

    /// @dev Trader swap exact amount of ETH for ERC20 Tokens (notice: msg.value = amountIn + oracle fee)
    /// @param  token The address of ERC20 Token
    /// @param  amountIn The exact amount of ETH a trader want to swap into pool
    /// @param  amountOutMin The minimum amount of Token a trader want to swap out of pool
    /// @param  to The target address receiving the Token
    /// @param  deadline The dealine of this request
    /// @return _amountIn The real amount of ETH transferred into pool
    /// @return _amountOut The real amount of Token transferred out of pool
    function swapExactETHForTokens(
        address token,
        uint amountIn,
        uint amountOutMin,
        address to,
        uint deadline
    ) external payable returns (uint _amountIn, uint _amountOut);

    /// @dev Trader swap exact amount of ERC20 Tokens for ETH (notice: msg.value = oracle fee)
    /// @param  token The address of ERC20 Token
    /// @param  amountIn The exact amount of Token a trader want to swap into pool
    /// @param  amountOutMin The mininum amount of ETH a trader want to swap out of pool
    /// @param  to The target address receiving the ETH
    /// @param  deadline The dealine of this request
    /// @return _amountIn The real amount of Token transferred into pool
    /// @return _amountOut The real amount of ETH transferred out of pool
    function swapExactTokensForETH(
        address token,
        uint amountIn,
        uint amountOutMin,
        address to,
        uint deadline
    ) external payable returns (uint _amountIn, uint _amountOut);

    /// @dev Trader swap ETH for exact amount of ERC20 Tokens (notice: msg.value = amountInMax + oracle fee)
    /// @param  token The address of ERC20 Token
    /// @param  amountInMax The max amount of ETH a trader want to swap into pool
    /// @param  amountOutExact The exact amount of Token a trader want to swap out of pool
    /// @param  to The target address receiving the Token
    /// @param  deadline The dealine of this request
    /// @return _amountIn The real amount of ETH transferred into pool
    /// @return _amountOut The real amount of Token transferred out of pool
    function swapETHForExactTokens(
        address token,
        uint amountInMax,
        uint amountOutExact,
        address to,
        uint deadline
    ) external payable returns (uint _amountIn, uint _amountOut);

    /// @dev Trader swap ERC20 Tokens for exact amount of ETH (notice: msg.value = oracle fee)
    /// @param  token The address of ERC20 Token
    /// @param  amountInMax The max amount of Token a trader want to swap into pool
    /// @param  amountOutExact The exact amount of ETH a trader want to swap out of pool
    /// @param  to The target address receiving the ETH
    /// @param  deadline The dealine of this request
    /// @return _amountIn The real amount of Token transferred into pool
    /// @return _amountOut The real amount of ETH transferred out of pool
    function swapTokensForExactETH(
        address token,
        uint amountInMax,
        uint amountOutExact,
        address to,
        uint deadline
    ) external payable returns (uint _amountIn, uint _amountOut); 
}

// 
// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "ds-math-div-zero");
        z = x / y;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    }
}

// 
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// 
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// 
interface ICoFiXERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    // function name() external pure returns (string memory);
    // function symbol() external pure returns (string memory);
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
}

// 
interface ICoFiXPair is ICoFiXERC20 {

    struct OraclePrice {
        uint256 ethAmount;
        uint256 erc20Amount;
        uint256 blockNum;
        uint256 K;
        uint256 theta;
    }
    
    // All pairs: {ETH <-> ERC20 Token}
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
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1);

    function mint(address to) external payable returns (uint liquidity, uint oracleFeeChange);
    function burn(address outToken, address to) external payable returns (uint amountOut, uint oracleFeeChange);
    function swapWithExact(address outToken, address to) external payable returns (uint amountIn, uint amountOut, uint oracleFeeChange);
    function swapForExact(address outToken, uint amountOutExact, address to) external payable returns (uint amountIn, uint amountOut, uint oracleFeeChange);
    function skim(address to) external;
    function sync() external;

    function initialize(address, address, string memory, string memory) external;
}

// 
contract CoFiXRouter is ICoFiXRouter {
    using SafeMath for uint;

    address public immutable override factory;
    address public immutable override WETH;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'CRouter: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {}

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address _factory, address token) internal view returns (address pair) {
        // pair = address(uint(keccak256(abi.encodePacked(
        //         hex'ff',
        //         _factory,
        //         keccak256(abi.encodePacked(token)),
        //         hex'fb0c5470b7fbfce7f512b5035b5c35707fd5c7bd43c8d81959891b0296030118' // init code hash
        //     )))); // calc the real init code hash, not suitable for us now, could use this in the future
        return ICoFiXFactory(_factory).getPair(token);
    }

    // msg.value = amountETH + oracle fee
    function addLiquidity(
        address token,
        uint amountETH,
        uint amountToken,
        uint liquidityMin,
        address to,
        uint deadline
    ) external override payable ensure(deadline) returns (uint liquidity)
    {
        // create the pair if it doesn't exist yet
        if (ICoFiXFactory(factory).getPair(token) == address(0)) {
            ICoFiXFactory(factory).createPair(token);
        }
        require(msg.value > amountETH, "CRouter: insufficient msg.value");
        uint256 _oracleFee = msg.value.sub(amountETH);
        address pair = pairFor(factory, token);
        if (amountToken > 0 ) { // support for tokens which do not allow to transfer zero values
            TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        }
        if (amountETH > 0) {
            IWETH(WETH).deposit{value: amountETH}();
            assert(IWETH(WETH).transfer(pair, amountETH));
        }
        uint256 oracleFeeChange;
        (liquidity, oracleFeeChange) = ICoFiXPair(pair).mint{value: _oracleFee}(to);
        require(liquidity >= liquidityMin, "CRouter: less liquidity than expected");
        // refund oracle fee to msg.sender, if any
        if (oracleFeeChange > 0) TransferHelper.safeTransferETH(msg.sender, oracleFeeChange);
    }

    // msg.value = oracle fee
    function removeLiquidityGetToken(
        address token,
        uint liquidity,
        uint amountTokenMin,
        address to,
        uint deadline
    ) external override payable ensure(deadline) returns (uint amountToken)
    {
        require(msg.value > 0, "CRouter: insufficient msg.value");
        address pair = pairFor(factory, token);
        ICoFiXPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        uint oracleFeeChange; 
        (amountToken, oracleFeeChange) = ICoFiXPair(pair).burn{value: msg.value}(token, to);
        require(amountToken >= amountTokenMin, "CRouter: got less than expected");
        // refund oracle fee to msg.sender, if any
        if (oracleFeeChange > 0) TransferHelper.safeTransferETH(msg.sender, oracleFeeChange);
    }

    // msg.value = oracle fee
    function removeLiquidityGetETH(
        address token,
        uint liquidity,
        uint amountETHMin,
        address to,
        uint deadline
    ) external override payable ensure(deadline) returns (uint amountETH)
    {
        require(msg.value > 0, "CRouter: insufficient msg.value");
        address pair = pairFor(factory, token);
        ICoFiXPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        uint oracleFeeChange; 
        (amountETH, oracleFeeChange) = ICoFiXPair(pair).burn{value: msg.value}(WETH, address(this));
        require(amountETH >= amountETHMin, "CRouter: got less than expected");
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
        // refund oracle fee to msg.sender, if any
        if (oracleFeeChange > 0) TransferHelper.safeTransferETH(msg.sender, oracleFeeChange);
    }

    // msg.value = amountIn + oracle fee
    function swapExactETHForTokens(
        address token,
        uint amountIn,
        uint amountOutMin,
        address to,
        uint deadline
    ) external override payable ensure(deadline) returns (uint _amountIn, uint _amountOut)
    {
        require(msg.value > amountIn, "CRouter: insufficient msg.value");
        IWETH(WETH).deposit{value: amountIn}();
        address pair = pairFor(factory, token);
        assert(IWETH(WETH).transfer(pair, amountIn));
        uint oracleFeeChange; 
        (_amountIn, _amountOut, oracleFeeChange) = ICoFiXPair(pair).swapWithExact{
            value: msg.value.sub(amountIn)}(token, to);
        require(_amountOut >= amountOutMin, "CRouter: got less than expected");
        // refund oracle fee to msg.sender, if any
        if (oracleFeeChange > 0) TransferHelper.safeTransferETH(msg.sender, oracleFeeChange);
    }

    // msg.value = oracle fee
    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMin,
        address to,
        uint deadline
    ) external payable ensure(deadline) returns (uint _amountIn, uint _amountOut) {
        // swapExactTokensForETH
        require(msg.value > 0, "CRouter: insufficient msg.value");
        address pairIn = pairFor(factory, tokenIn);
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, pairIn, amountIn);
        uint oracleFeeChange; 
        (_amountIn, _amountOut, oracleFeeChange) = ICoFiXPair(pairIn).swapWithExact{value: msg.value}(WETH, address(this));

        // swapExactETHForTokens
        address pairOut = pairFor(factory, tokenOut);
        assert(IWETH(WETH).transfer(pairOut, _amountOut)); // swap with all amountOut in last swap
        (, _amountOut, oracleFeeChange) = ICoFiXPair(pairOut).swapWithExact{value: oracleFeeChange}(tokenOut, to);
        require(_amountOut >= amountOutMin, "CRouter: got less than expected");
        // refund oracle fee to msg.sender, if any
        if (oracleFeeChange > 0) TransferHelper.safeTransferETH(msg.sender, oracleFeeChange);
    }

    // msg.value = oracle fee
    function swapExactTokensForETH(
        address token,
        uint amountIn,
        uint amountOutMin,
        address to,
        uint deadline
    ) external override payable ensure(deadline) returns (uint _amountIn, uint _amountOut)
    {
        require(msg.value > 0, "CRouter: insufficient msg.value");
        address pair = pairFor(factory, token);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountIn);
        uint oracleFeeChange; 
        (_amountIn, _amountOut, oracleFeeChange) = ICoFiXPair(pair).swapWithExact{value: msg.value}(WETH, address(this));
        require(_amountOut >= amountOutMin, "CRouter: got less than expected");
        IWETH(WETH).withdraw(_amountOut);
        TransferHelper.safeTransferETH(to, _amountOut);
        // refund oracle fee to msg.sender, if any
        if (oracleFeeChange > 0) TransferHelper.safeTransferETH(msg.sender, oracleFeeChange);
    }

    // msg.value = amountInMax + oracle fee
    function swapETHForExactTokens(
        address token,
        uint amountInMax,
        uint amountOutExact,
        address to,
        uint deadline
    ) external override payable ensure(deadline) returns (uint _amountIn, uint _amountOut)
    {
        require(msg.value > amountInMax, "CRouter: insufficient msg.value");
        IWETH(WETH).deposit{value: amountInMax}();
        address pair = pairFor(factory, token);
        assert(IWETH(WETH).transfer(pair, amountInMax));
        uint oracleFeeChange; 
        (_amountIn, _amountOut, oracleFeeChange) = ICoFiXPair(pair).swapForExact{
            value: msg.value.sub(amountInMax) }(token, amountOutExact, to);
        // assert amountOutExact equals with _amountOut
        require(_amountIn <= amountInMax, "CRouter: spend more than expected");
        if (oracleFeeChange > 0) TransferHelper.safeTransferETH(msg.sender, oracleFeeChange);
    }

    // msg.value = oracle fee
    function swapTokensForExactETH(
        address token,
        uint amountInMax,
        uint amountOutExact,
        address to,
        uint deadline
    ) external override payable ensure(deadline) returns (uint _amountIn, uint _amountOut)
    {
        require(msg.value > 0, "CRouter: insufficient msg.value");
        address pair = pairFor(factory, token);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountInMax);
        uint oracleFeeChange; 
        (_amountIn, _amountOut, oracleFeeChange) = ICoFiXPair(pair).swapForExact{
            value: msg.value}(WETH, amountOutExact, address(this));
        // assert amountOutExact equals with _amountOut
        require(_amountIn <= amountInMax, "CRouter: got less than expected");
        IWETH(WETH).withdraw(_amountOut);
        TransferHelper.safeTransferETH(to, amountOutExact);
        // refund oracle fee to msg.sender, if any
        if (oracleFeeChange > 0) TransferHelper.safeTransferETH(msg.sender, oracleFeeChange);
    }
}