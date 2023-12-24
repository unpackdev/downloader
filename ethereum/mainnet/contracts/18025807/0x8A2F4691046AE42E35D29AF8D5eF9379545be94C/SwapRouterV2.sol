pragma solidity =0.6.6;

import "./TransferHelper.sol";

import "./IUniswapV2Router02.sol";
import "./SwapRouterV2Library.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IWETH.sol";
import "./IUniswapV2Factory.sol";

contract SwapRouterV2 {
    using SafeMath for uint;

    address public immutable factoryMain;
    address public immutable factorySecondary;
    address public immutable WETH;

    bytes constant MAIN_PAIR_INIT_CODE = hex'e973e3d886c55dcdd68af79ba1794ef0161db147d6a5eda7d2bf70fce9265a03';
    bytes constant SECONDARY_PAIR_INIT_CODE = hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f';

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    constructor(address _factoryMain, address _factorySecondary, address _WETH) public {
        factoryMain = _factoryMain;
        factorySecondary = _factorySecondary;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IUniswapV2Factory(factoryMain).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factoryMain).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = SwapRouterV2Library.getReserves(factoryMain, tokenA, tokenB, MAIN_PAIR_INIT_CODE);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = SwapRouterV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = SwapRouterV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = SwapRouterV2Library.pairFor(factoryMain, tokenA, tokenB, MAIN_PAIR_INIT_CODE);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = SwapRouterV2Library.pairFor(factoryMain, token, WETH, MAIN_PAIR_INIT_CODE);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IUniswapV2Pair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = SwapRouterV2Library.pairFor(factoryMain, tokenA, tokenB, MAIN_PAIR_INIT_CODE);
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0,) = SwapRouterV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB) {
        address pair = SwapRouterV2Library.pairFor(factoryMain, tokenA, tokenB, MAIN_PAIR_INIT_CODE);
        uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH) {
        address pair = SwapRouterV2Library.pairFor(factoryMain, token, WETH, MAIN_PAIR_INIT_CODE);
        uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH) {
        address pair = SwapRouterV2Library.pairFor(factoryMain, token, WETH, MAIN_PAIR_INIT_CODE);
        uint value = approveMax ? uint(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to, bool isUni) internal {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = SwapRouterV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? SwapRouterV2Library.pairFor(isUni ? factorySecondary : factoryMain, output, path[i + 2], isUni ? SECONDARY_PAIR_INIT_CODE : MAIN_PAIR_INIT_CODE) : _to;
            IUniswapV2Pair(SwapRouterV2Library.pairFor(isUni ? factorySecondary : factoryMain, input, output, isUni ? SECONDARY_PAIR_INIT_CODE : MAIN_PAIR_INIT_CODE)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        bool isUni
    ) external ensure(deadline) returns (uint[] memory amounts) {
        amounts = SwapRouterV2Library.getAmountsOut(
            isUni ? factorySecondary : factoryMain, amountIn,
            isUni ? 0 : IUniswapV2Factory(factoryMain).swapFeeBP(),
            path,
            isUni ? SECONDARY_PAIR_INIT_CODE : MAIN_PAIR_INIT_CODE);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SwapRouterV2Library.pairFor(isUni ? factorySecondary : factoryMain, path[0], path[1], isUni ? SECONDARY_PAIR_INIT_CODE : MAIN_PAIR_INIT_CODE), amounts[0]
        );
        _swap(amounts, path, to, isUni);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline,
        bool isUni
    ) external ensure(deadline) returns (uint[] memory amounts) {
        amounts = SwapRouterV2Library.getAmountsIn(isUni ? factorySecondary : factoryMain, amountOut, isUni ? 0 : IUniswapV2Factory(factoryMain).swapFeeBP(), path, isUni ? SECONDARY_PAIR_INIT_CODE : MAIN_PAIR_INIT_CODE);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SwapRouterV2Library.pairFor(isUni ? factorySecondary : factoryMain, path[0], path[1], isUni ? SECONDARY_PAIR_INIT_CODE : MAIN_PAIR_INIT_CODE), amounts[0]
        );
        _swap(amounts, path, to, isUni);
    }
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline, bool isUni)
    external
    payable
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = SwapRouterV2Library.getAmountsOut(isUni ? factorySecondary : factoryMain, msg.value, isUni ? 0 : IUniswapV2Factory(factoryMain).swapFeeBP(), path, isUni ? SECONDARY_PAIR_INIT_CODE : MAIN_PAIR_INIT_CODE);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(SwapRouterV2Library.pairFor(isUni ? factorySecondary : factoryMain, path[0], path[1], isUni ? SECONDARY_PAIR_INIT_CODE : MAIN_PAIR_INIT_CODE), amounts[0]));
        _swap(amounts, path, to, isUni);
    }
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline, bool isUni)
    external
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = SwapRouterV2Library.getAmountsIn(isUni ? factorySecondary : factoryMain, amountOut, isUni ? 0 : IUniswapV2Factory(factoryMain).swapFeeBP(), path, isUni ? SECONDARY_PAIR_INIT_CODE : MAIN_PAIR_INIT_CODE);
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SwapRouterV2Library.pairFor(isUni ? factorySecondary : factoryMain, path[0], path[1], isUni ? SECONDARY_PAIR_INIT_CODE : MAIN_PAIR_INIT_CODE), amounts[0]
        );
        _swap(amounts, path, address(this), isUni);
        uint256 withdrawAmount = isUni ? amounts[amounts.length - 1] : amounts[amounts.length - 1] - amounts[amounts.length - 1] * IUniswapV2Factory(factoryMain).swapFeeBP() / 10000;
        IWETH(WETH).withdraw(withdrawAmount);
        TransferHelper.safeTransferETH(to, withdrawAmount);
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, bool isUni)
    external
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = SwapRouterV2Library.getAmountsOut(isUni ? factorySecondary : factoryMain, amountIn, isUni ? 0 : IUniswapV2Factory(factoryMain).swapFeeBP(), path, isUni ? SECONDARY_PAIR_INIT_CODE : MAIN_PAIR_INIT_CODE);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SwapRouterV2Library.pairFor(isUni ? factorySecondary : factoryMain, path[0], path[1], isUni ? SECONDARY_PAIR_INIT_CODE : MAIN_PAIR_INIT_CODE), amounts[0]
        );
        _swap(amounts, path, address(this), isUni);
        uint256 withdrawAmount = isUni ? amounts[amounts.length - 1] : amounts[amounts.length - 1] - amounts[amounts.length - 1] * IUniswapV2Factory(factoryMain).swapFeeBP() / 10000;
        IWETH(WETH).withdraw(withdrawAmount);
        TransferHelper.safeTransferETH(to, withdrawAmount);
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline, bool isUni)
    external
    payable
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        amounts = SwapRouterV2Library.getAmountsIn(isUni ? factorySecondary : factoryMain, amountOut, isUni ? 0 : IUniswapV2Factory(factoryMain).swapFeeBP(), path, isUni ? SECONDARY_PAIR_INIT_CODE : MAIN_PAIR_INIT_CODE);
        require(amounts[0] <= msg.value, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(SwapRouterV2Library.pairFor(isUni ? factorySecondary : factoryMain, path[0], path[1], isUni ? SECONDARY_PAIR_INIT_CODE : MAIN_PAIR_INIT_CODE), amounts[0]));
        _swap(amounts, path, to, isUni);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to, bool isUni) internal  {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = SwapRouterV2Library.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(SwapRouterV2Library.pairFor(isUni ? factorySecondary : factoryMain, input, output, isUni ? SECONDARY_PAIR_INIT_CODE : MAIN_PAIR_INIT_CODE));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
                (uint reserve0, uint reserve1,) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = SwapRouterV2Library.getAmountOut(amountInput, reserveInput, reserveOutput, isUni ? 0 : IUniswapV2Factory(factoryMain).swapFeeBP());
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? SwapRouterV2Library.pairFor(isUni ? factorySecondary : factoryMain, output, path[i + 2], isUni ? SECONDARY_PAIR_INIT_CODE : MAIN_PAIR_INIT_CODE) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        bool isUni
    ) external ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SwapRouterV2Library.pairFor(isUni ? factorySecondary : factoryMain, path[0], path[1], isUni ? SECONDARY_PAIR_INIT_CODE : MAIN_PAIR_INIT_CODE), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to, isUni);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        bool isUni
    )
    external
    payable
    ensure(deadline)
    {
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(SwapRouterV2Library.pairFor(isUni ? factorySecondary : factoryMain, path[0], path[1], isUni ? SECONDARY_PAIR_INIT_CODE : MAIN_PAIR_INIT_CODE), amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to, isUni);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        bool isUni
    )
    external
    ensure(deadline)
    {
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SwapRouterV2Library.pairFor(isUni ? factorySecondary : factoryMain, path[0], path[1], isUni ? SECONDARY_PAIR_INIT_CODE : MAIN_PAIR_INIT_CODE), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this), isUni);
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }
}
