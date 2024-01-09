pragma solidity =0.6.6;

import "./ISphynxFactory.sol";
import "./TransferHelper.sol";

import "./ISphynxRouter.sol";
import "./SphynxLibrary.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IWETH.sol";

contract SphynxRewardFeeRouter is ISphynxRouter {
    using SafeMath for uint;

    address public immutable override factory;
    address public immutable override WETH;
    address public swapfeeSetter;
    mapping(address => uint256) public feeCollected;
    uint256 swapFee = 1; // 0.1% swap fee default

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'SphynxRouter: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH, address _feeSetter) public {
        factory = _factory;
        WETH = _WETH;
        swapfeeSetter = _feeSetter;
    }

    function updateSwapFee(uint256 _swapFee) external {
        require(msg.sender == swapfeeSetter, "SphynxRouter: UNABLE To SET FEE");
        swapFee = _swapFee;
    }

    function updateSwapFeeSettor(address _swapFeeSetter) external {
        require(msg.sender == swapfeeSetter, "SphynxRouter: Not Fee Setter");
        swapfeeSetter = _swapFeeSetter;
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
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (ISphynxFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            ISphynxFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = SphynxLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = SphynxLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'SphynxRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = SphynxLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'SphynxRouter: INSUFFICIENT_A_AMOUNT');
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
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = SphynxLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = ISphynxPair(pair).mint(to);
    }
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = SphynxLibrary.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = ISphynxPair(pair).mint(to);
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
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = SphynxLibrary.pairFor(factory, tokenA, tokenB);
        ISphynxPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = ISphynxPair(pair).burn(to);
        (address token0,) = SphynxLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'SphynxRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'SphynxRouter: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
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
    ) external virtual override returns (uint amountA, uint amountB) {
        address pair = SphynxLibrary.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? uint(-1) : liquidity;
        ISphynxPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
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
    ) external virtual override returns (uint amountToken, uint amountETH) {
        address pair = SphynxLibrary.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        ISphynxPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
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
    ) public virtual override ensure(deadline) returns (uint amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, (IERC20(token).balanceOf(address(this))).sub(feeCollected[token]));
        uint256 realBalance = IERC20(WETH).balanceOf(address(this));
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
    ) external virtual override returns (uint amountETH) {
        address pair = SphynxLibrary.pairFor(factory, token, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        ISphynxPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = SphynxLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? SphynxLibrary.pairFor(factory, output, path[i + 2]) : _to;
            ISphynxPair(SphynxLibrary.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = SphynxLibrary.getAmountsOut(factory, amountIn * (1000 - swapFee) / 1000, path); // 0.1% swap fee
        require(amounts[amounts.length - 1] >= amountOutMin, 'SphynxRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SphynxLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        // TransferHelper.safeTransferFrom(path[0], msg.sender, ISphynxFactory(factory).feeTo(), amounts[0] * swapFee / 1000); // 0.1% default swap fee(withdraw at once)
        feeCollected[path[0]] = feeCollected[path[0]].add(amounts[0] * swapFee / 1000);
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = SphynxLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] * (1000 + swapFee) / 1000 <= amountInMax, 'SphynxRouter: EXCESSIVE_INPUT_AMOUNT'); // 0.1% default swap fee check
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SphynxLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        // TransferHelper.safeTransferFrom(path[0], msg.sender, ISphynxFactory(factory).feeTo(), amounts[0] * swapFee / 1000); // 0.1% default swap fee
        feeCollected[path[0]] = feeCollected[path[0]].add(amounts[0] * swapFee / 1000);
        _swap(amounts, path, to);
    }
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'SphynxRouter: INVALID_PATH');
        amounts = SphynxLibrary.getAmountsOut(factory, msg.value * (1000 - swapFee) / 1000, path); // 0.1% swap fee default
        require(amounts[amounts.length - 1] >= amountOutMin, 'SphynxRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(SphynxLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        //TransferHelper.safeTransferETH(ISphynxFactory(factory).feeTo(), msg.value * swapFee / 1000); // 0.1% swap fee default(withdraw at once)
    }
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'SphynxRouter: INVALID_PATH');
        amounts = SphynxLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'SphynxRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SphynxLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1] * (1000 - swapFee) / 1000); // 0.1% swap fee default
        //TransferHelper.safeTransferETH(ISphynxFactory(factory).feeTo(), amounts[amounts.length - 1] * swapFee / 1000); // 0.1% swap fee default(withdraw at once)
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'SphynxRouter: INVALID_PATH');
        amounts = SphynxLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'SphynxRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SphynxLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1] * (1000 - swapFee) / 1000); // 0.1% swap fee default
        //TransferHelper.safeTransferETH(ISphynxFactory(factory).feeTo(), amounts[amounts.length - 1] * swapFee / 1000); // 0.1% swap fee default(withdraw at once)
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'SphynxRouter: INVALID_PATH');
        amounts = SphynxLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] * (1000 + swapFee) / 1000 <= msg.value, 'SphynxRouter: EXCESSIVE_INPUT_AMOUNT'); // swap fee check
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(SphynxLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        //TransferHelper.safeTransferETH(ISphynxFactory(factory).feeTo(), amounts[0] * swapFee / 1000); // 0.1% swap fee(withdraw at once)
        // refund dust eth, if any
        if (msg.value > amounts[0] * (1000 + swapFee) / 1000) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0] * (1000 + swapFee) / 1000); // 0.1% swap fee
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = SphynxLibrary.sortTokens(input, output);
            ISphynxPair pair = ISphynxPair(SphynxLibrary.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = SphynxLibrary.getAmountOut(amountInput, reserveInput, reserveOutput, pair.swapFee());
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? SphynxLibrary.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SphynxLibrary.pairFor(factory, path[0], path[1]), amountIn * (1000 - swapFee) / 1000
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'SphynxRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
        // TransferHelper.safeTransferFrom(
        //     path[0], msg.sender, ISphynxFactory(factory).feeTo(), amountIn * swapFee / 1000
        // ); // 0.1% default swap fee(withdraw at once)
        feeCollected[path[0]] = feeCollected[path[0]].add(amountIn * swapFee / 1000);
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        payable
        ensure(deadline)
    {
        require(path[0] == WETH, 'SphynxRouter: INVALID_PATH');
        uint amountIn = msg.value * (1000 - swapFee) / 1000; //0.1% swap fee default
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(SphynxLibrary.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'SphynxRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
        // TransferHelper.safeTransferETH(ISphynxFactory(factory).feeTo(), msg.value * swapFee / 1000); // 0.1% swap fee default(withdraw at once)
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        ensure(deadline)
    {
        require(path[path.length - 1] == WETH, 'SphynxRouter: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SphynxLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'SphynxRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut * (1000 - swapFee) / 1000); //0.1% swap fee default
        // TransferHelper.safeTransferETH(ISphynxFactory(factory).feeTo(), amountOut * swapFee / 1000); // 0.1% swap fee default(withdraw at once)
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return SphynxLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint _swapFee)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return SphynxLibrary.getAmountOut(amountIn, reserveIn, reserveOut, _swapFee);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint _swapFee)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return SphynxLibrary.getAmountIn(amountOut, reserveIn, reserveOut, _swapFee);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return SphynxLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return SphynxLibrary.getAmountsIn(factory, amountOut, path);
    }

    function withdrawToken(address _token) external {
        require(msg.sender == ISphynxFactory(factory).feeTo(), "permission-denied");
        IERC20 token = IERC20(_token);
        TransferHelper.safeTransfer(_token, msg.sender, token.balanceOf(address(this)));
        feeCollected[_token] = 0;
    }

    function withdrawNativeCoin() external payable {
        require(msg.sender == ISphynxFactory(factory).feeTo(), "permission-denied");
        address payable msgSender = payable(msg.sender);
        msgSender.transfer(address(this).balance);
    }
}