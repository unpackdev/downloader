// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import "./ConfigNames.sol";
import "./SafeMath.sol";
import "./TransferHelper.sol";
import "./TomiSwapLibrary.sol";
import "./IWETH.sol";
import "./ITomiGovernance.sol";
import "./ITomiConfig.sol";
import "./IERC20.sol";
import "./ITomiFactory.sol";
import "./ITomiPair.sol";
import "./ITomiPool.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ITomiTransferListener.sol";
import "./ITokenRegistry.sol";
import "./ITomiStaking.sol";

contract TomiPlatform is Ownable {
    uint256 public version = 1;
    address public TOMI;
    address public CONFIG;
    address public FACTORY;
    address public WETH;
    address public GOVERNANCE;
    address public TRANSFER_LISTENER;
    address public POOL;
    uint256 public constant PERCENT_DENOMINATOR = 10000;

    bool public isPause;

    event AddLiquidity(
        address indexed player,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB
    );
    event RemoveLiquidity(
        address indexed player,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB
    );
    event SwapToken(
        address indexed receiver,
        address indexed fromToken,
        address indexed toToken,
        uint256 inAmount,
        uint256 outAmount
    );

    receive() external payable {
        assert(msg.sender == WETH);
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'TOMI PLATFORM : EXPIRED');
        _;
    }

    modifier noneTokenCall() {
        require(ITokenRegistry(CONFIG).tokenStatus(msg.sender) == 0, 'TOMI PLATFORM : ILLEGAL CALL');
        _;
    }

    function initialize(
        address _TOMI,
        address _CONFIG,
        address _FACTORY,
        address _WETH,
        address _GOVERNANCE,
        address _TRANSFER_LISTENER,
        address _POOL
    ) external onlyOwner {
        TOMI = _TOMI;
        CONFIG = _CONFIG;
        FACTORY = _FACTORY;
        WETH = _WETH;
        GOVERNANCE = _GOVERNANCE;
        TRANSFER_LISTENER = _TRANSFER_LISTENER;
        POOL = _POOL;
    }

    function pause() external onlyOwner {
        isPause = true;
    }

    function resume() external onlyOwner {
        isPause = false;
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB) {
        if (ITomiFactory(FACTORY).getPair(tokenA, tokenB) == address(0)) {
            ITomiConfig(CONFIG).addToken(tokenA);
            ITomiConfig(CONFIG).addToken(tokenB);
            ITomiFactory(FACTORY).createPair(tokenA, tokenB);
        }
        require(
            ITomiConfig(CONFIG).checkPair(tokenA, tokenB),
            'TOMI PLATFORM : ADD LIQUIDITY PAIR CONFIG CHECK FAIL'
        );
        (uint256 reserveA, uint256 reserveB) = TomiSwapLibrary.getReserves(FACTORY, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = TomiSwapLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'TOMI PLATFORM : INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = TomiSwapLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'TOMI PLATFORM : INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
        ITomiFactory(FACTORY).addPlayerPair(msg.sender, ITomiFactory(FACTORY).getPair(tokenA, tokenB));
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    )
        external
        ensure(deadline)
        returns (
            uint256 _amountA,
            uint256 _amountB,
            uint256 _liquidity
        )
{
        require(!isPause, "TOMI PAUSED");
        (_amountA, _amountB) = _addLiquidity(tokenA, tokenB, amountA, amountB, amountAMin, amountBMin);
        address pair = TomiSwapLibrary.pairFor(FACTORY, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, _amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, _amountB);

        // notify pool
        ITomiPool(POOL).preProductivityChanged(pair, msg.sender);
        _liquidity = ITomiPair(pair).mint(msg.sender);
        ITomiPool(POOL).postProductivityChanged(pair, msg.sender);

        _transferNotify(msg.sender, pair, tokenA, _amountA);
        _transferNotify(msg.sender, pair, tokenB, _amountB);
        emit AddLiquidity(msg.sender, tokenA, tokenB, _amountA, _amountB);
    }

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
    )
        external
        payable
        ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        require(!isPause, "TOMI PAUSED");
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = TomiSwapLibrary.pairFor(FACTORY, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));

        // notify pool
        ITomiPool(POOL).preProductivityChanged(pair, msg.sender);
        liquidity = ITomiPair(pair).mint(msg.sender);
        ITomiPool(POOL).postProductivityChanged(pair, msg.sender);

        _transferNotify(msg.sender, pair, WETH, amountETH);
        _transferNotify(msg.sender, pair, token, amountToken);
        emit AddLiquidity(msg.sender, token, WETH, amountToken, amountETH);
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        require(!isPause, "TOMI PAUSED");
        address pair = TomiSwapLibrary.pairFor(FACTORY, tokenA, tokenB);
        uint256 _liquidity = liquidity;
        address _tokenA = tokenA;
        address _tokenB = tokenB;

        // notify pool
        ITomiPool(POOL).preProductivityChanged(pair, msg.sender);
        (uint256 amount0, uint256 amount1) = ITomiPair(pair).burn(msg.sender, to, _liquidity);
        ITomiPool(POOL).postProductivityChanged(pair, msg.sender);

        (address token0, ) = TomiSwapLibrary.sortTokens(_tokenA, _tokenB);
        (amountA, amountB) = _tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        _transferNotify(pair, to, _tokenA, amountA);
        _transferNotify(pair, to, _tokenB, amountB);
        require(amountA >= amountAMin, 'TOMI PLATFORM : INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'TOMI PLATFORM : INSUFFICIENT_B_AMOUNT');
        emit RemoveLiquidity(msg.sender, _tokenA, _tokenB, amountA, amountB);
    }

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
        require(!isPause, "TOMI PAUSED");
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
        _transferNotify(address(this), to, token, amountToken);
        _transferNotify(address(this), to, WETH, amountETH);
    }

    function _getAmountsOut(
        uint256 amount,
        address[] memory path,
        uint256 percent
    ) internal view returns (uint256[] memory amountOuts) {
        amountOuts = new uint256[](path.length);
        amountOuts[0] = amount;
        for (uint256 i = 0; i < path.length - 1; i++) {
            address inPath = path[i];
            address outPath = path[i + 1];
            (uint256 reserveA, uint256 reserveB) = TomiSwapLibrary.getReserves(FACTORY, inPath, outPath);
            uint256 outAmount = SafeMath.mul(amountOuts[i], SafeMath.sub(PERCENT_DENOMINATOR, percent));
            amountOuts[i + 1] = TomiSwapLibrary.getAmountOut(outAmount / PERCENT_DENOMINATOR, reserveA, reserveB);
        }
    }

    function _getAmountsIn(
        uint256 amount,
        address[] memory path,
        uint256 percent
    ) internal view returns (uint256[] memory amountIn) {
        amountIn = new uint256[](path.length);
        amountIn[path.length - 1] = amount;
        for (uint256 i = path.length - 1; i > 0; i--) {
            address inPath = path[i - 1];
            address outPath = path[i];
            (uint256 reserveA, uint256 reserveB) = TomiSwapLibrary.getReserves(FACTORY, inPath, outPath);
            uint256 inAmount = TomiSwapLibrary.getAmountIn(amountIn[i], reserveA, reserveB);
            amountIn[i - 1] = SafeMath.add(
                SafeMath.mul(inAmount, PERCENT_DENOMINATOR) / SafeMath.sub(PERCENT_DENOMINATOR, percent),
                1
            );
        }
        amountIn = _getAmountsOut(amountIn[0], path, percent);
    }

    function swapPrecondition(address token) public view returns (bool) {
        if (token == TOMI || token == WETH) return true;
        uint256 percent = ITomiConfig(CONFIG).getConfigValue(ConfigNames.TOKEN_TO_TGAS_PAIR_MIN_PERCENT);
        if (!existPair(WETH, TOMI)) return false;
        if (!existPair(TOMI, token)) return false;
        if (!(ITomiConfig(CONFIG).checkPair(TOMI, token) && ITomiConfig(CONFIG).checkPair(WETH, token))) return false;
        if (!existPair(WETH, token)) return true;
        if (percent == 0) return true;
        (uint256 reserveTOMI, ) = TomiSwapLibrary.getReserves(FACTORY, TOMI, token);
        (uint256 reserveWETH, ) = TomiSwapLibrary.getReserves(FACTORY, WETH, token);
        (uint256 reserveWETH2, uint256 reserveTOMI2) = TomiSwapLibrary.getReserves(FACTORY, WETH, TOMI);
        uint256 tomiValue = SafeMath.mul(reserveTOMI, reserveWETH2) / reserveTOMI2;
        uint256 limitValue = SafeMath.mul(SafeMath.add(tomiValue, reserveWETH), percent) / PERCENT_DENOMINATOR;
        return tomiValue >= limitValue;
    }
         
    function checkPath(address _path, address[] memory _paths) public pure returns (bool) {
        uint count;
        for(uint i; i<_paths.length; i++) {
            if(_paths[i] == _path) {
                count++;
            }
        }
        if(count == 1) {
            return true;
        } else {
            return false;
        }
    }

    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal {
        require(!isPause, "TOMI PAUSED");
        require(swapPrecondition(path[path.length - 1]), 'TOMI PLATFORM : CHECK TOMI/TOKEN TO VALUE FAIL');
        for (uint256 i; i < path.length - 1; i++) {
            require(checkPath(path[i], path) && checkPath(path[i + 1], path), 'DEMAX PLATFORM : INVALID PATH');
            (address input, address output) = (path[i], path[i + 1]);
            require(swapPrecondition(input), 'TOMI PLATFORM : CHECK TOMI/TOKEN VALUE FROM FAIL');
            require(ITomiConfig(CONFIG).checkPair(input, output), 'TOMI PLATFORM : SWAP PAIR CONFIG CHECK FAIL');
            (address token0, address token1) = TomiSwapLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2 ? TomiSwapLibrary.pairFor(FACTORY, output, path[i + 2]) : _to;

            // add k check
            address pair = TomiSwapLibrary.pairFor(FACTORY, input, output);
            (uint reserve0, uint resereve1, ) = ITomiPair(pair).getReserves();
            uint kBefore = SafeMath.mul(reserve0, resereve1);

            ITomiPair(pair).swap(amount0Out, amount1Out, to, new bytes(0));

            (reserve0, resereve1, ) = ITomiPair(pair).getReserves();
            uint kAfter = SafeMath.mul(reserve0, resereve1);
            require(kBefore <= kAfter, "Burger K");

            if (amount0Out > 0)
                _transferNotify(TomiSwapLibrary.pairFor(FACTORY, input, output), to, token0, amount0Out);
            if (amount1Out > 0)
                _transferNotify(TomiSwapLibrary.pairFor(FACTORY, input, output), to, token1, amount1Out);
        }
        emit SwapToken(_to, path[0], path[path.length - 1], amounts[0], amounts[path.length - 1]);
    }

    function _swapFee(
        uint256[] memory amounts,
        address[] memory path,
        uint256 percent
    ) internal {
        for (uint256 i = 0; i < path.length - 1; i++) {
            uint256 fee = SafeMath.mul(amounts[i], percent) / PERCENT_DENOMINATOR;
            address input = path[i];
            address output = path[i + 1];
            address currentPair = TomiSwapLibrary.pairFor(FACTORY, input, output);
            if (input == TOMI) {
                ITomiPair(currentPair).swapFee(fee, TOMI, POOL);
                _transferNotify(currentPair, POOL, TOMI, fee);
            } else {
                ITomiPair(currentPair).swapFee(fee, input, TomiSwapLibrary.pairFor(FACTORY, input, TOMI));
                (uint256 reserveIn, uint256 reserveTOMI) = TomiSwapLibrary.getReserves(FACTORY, input, TOMI);
                uint256 feeOut = TomiSwapLibrary.getAmountOut(fee, reserveIn, reserveTOMI);
                ITomiPair(TomiSwapLibrary.pairFor(FACTORY, input, TOMI)).swapFee(feeOut, TOMI, POOL);
                _transferNotify(currentPair, TomiSwapLibrary.pairFor(FACTORY, input, TOMI), input, fee);
                _transferNotify(TomiSwapLibrary.pairFor(FACTORY, input, TOMI), POOL, TOMI, feeOut);
                fee = feeOut;
            }
            if (fee > 0) { 
                ITomiPool(POOL).addRewardFromPlatform(currentPair, fee); 
            }
        }
    }

    function _getSwapFeePercent() internal view returns (uint256) {
        return ITomiConfig(CONFIG).getConfigValue(ConfigNames.SWAP_FEE_PERCENT);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {

        uint256 percent = _getSwapFeePercent();
        amounts = _getAmountsOut(amountIn, path, percent);
        require(amounts[amounts.length - 1] >= amountOutMin, 'TOMI PLATFORM : INSUFFICIENT_OUTPUT_AMOUNT');
        address pair = TomiSwapLibrary.pairFor(FACTORY, path[0], path[1]);
        _innerTransferFrom(
            path[0],
            msg.sender,
            pair,
            SafeMath.mul(amountIn, SafeMath.sub(PERCENT_DENOMINATOR, percent)) / PERCENT_DENOMINATOR
        );
        _swap(amounts, path, to);
        _innerTransferFrom(path[0], msg.sender, pair, SafeMath.mul(amounts[0], percent) / PERCENT_DENOMINATOR);
        _swapFee(amounts, path, percent);
    }

    function _innerTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        TransferHelper.safeTransferFrom(token, from, to, amount);
        _transferNotify(from, to, token, amount);
    }

    function _innerTransferWETH(address to, uint256 amount) internal {
        assert(IWETH(WETH).transfer(to, amount));
        _transferNotify(address(this), to, WETH, amount);
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable ensure(deadline) returns (uint256[] memory amounts) {
        require(path[0] == WETH, 'TOMI PLATFORM : INVALID_PATH');
        uint256 percent = _getSwapFeePercent();
        amounts = _getAmountsOut(msg.value, path, percent);
        require(amounts[amounts.length - 1] >= amountOutMin, 'TOMI PLATFORM : INSUFFICIENT_OUTPUT_AMOUNT');
        address pair = TomiSwapLibrary.pairFor(FACTORY, path[0], path[1]);
        IWETH(WETH).deposit{
            value: SafeMath.mul(amounts[0], SafeMath.sub(PERCENT_DENOMINATOR, percent)) / PERCENT_DENOMINATOR
        }();
        _innerTransferWETH(
            pair,
            SafeMath.mul(amounts[0], SafeMath.sub(PERCENT_DENOMINATOR, percent)) / PERCENT_DENOMINATOR
        );
        _swap(amounts, path, to);

        IWETH(WETH).deposit{value: SafeMath.mul(amounts[0], percent) / PERCENT_DENOMINATOR}();
        _innerTransferWETH(pair, SafeMath.mul(amounts[0], percent) / PERCENT_DENOMINATOR);
        _swapFee(amounts, path, percent);
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WETH, 'TOMI PLATFORM : INVALID_PATH');
        uint256 percent = _getSwapFeePercent();
        amounts = _getAmountsOut(amountIn, path, percent);
        require(amounts[amounts.length - 1] >= amountOutMin, 'TOMI PLATFORM : INSUFFICIENT_OUTPUT_AMOUNT');
        address pair = TomiSwapLibrary.pairFor(FACTORY, path[0], path[1]);
        _innerTransferFrom(
            path[0],
            msg.sender,
            pair,
            SafeMath.mul(amountIn, SafeMath.sub(PERCENT_DENOMINATOR, percent)) / PERCENT_DENOMINATOR
        );
        _swap(amounts, path, address(this));

        _innerTransferFrom(path[0], msg.sender, pair, SafeMath.mul(amounts[0], percent) / PERCENT_DENOMINATOR);
        _swapFee(amounts, path, percent);

        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        uint256 percent = _getSwapFeePercent();
        amounts = _getAmountsIn(amountOut, path, percent);
        require(amounts[0] <= amountInMax, 'TOMI PLATFORM : EXCESSIVE_INPUT_AMOUNT');
        address pair = TomiSwapLibrary.pairFor(FACTORY, path[0], path[1]);

        _innerTransferFrom(
            path[0],
            msg.sender,
            pair,
            SafeMath.mul(amounts[0], SafeMath.sub(PERCENT_DENOMINATOR, percent)) / PERCENT_DENOMINATOR
        );
        _swap(amounts, path, to);
        _innerTransferFrom(path[0], msg.sender, pair, SafeMath.mul(amounts[0], percent) / PERCENT_DENOMINATOR);
        _swapFee(amounts, path, percent);
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WETH, 'TOMI PLATFORM : INVALID_PATH');
        uint256 percent = _getSwapFeePercent();
        amounts = _getAmountsIn(amountOut, path, percent);
        require(amounts[0] <= amountInMax, 'TOMI PLATFORM : EXCESSIVE_INPUT_AMOUNT');
        address pair = TomiSwapLibrary.pairFor(FACTORY, path[0], path[1]);
        _innerTransferFrom(
            path[0],
            msg.sender,
            pair,
            SafeMath.mul(amounts[0], SafeMath.sub(PERCENT_DENOMINATOR, percent)) / PERCENT_DENOMINATOR
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);

        _innerTransferFrom(path[0], msg.sender, pair, SafeMath.mul(amounts[0], percent) / PERCENT_DENOMINATOR);
        _swapFee(amounts, path, percent);
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable ensure(deadline) returns (uint256[] memory amounts) {
        require(path[0] == WETH, 'TOMI PLATFORM : INVALID_PATH');
        uint256 percent = _getSwapFeePercent();
        amounts = _getAmountsIn(amountOut, path, percent);
        require(amounts[0] <= msg.value, 'TOMI PLATFORM : EXCESSIVE_INPUT_AMOUNT');

        IWETH(WETH).deposit{
            value: SafeMath.mul(amounts[0], SafeMath.sub(PERCENT_DENOMINATOR, percent)) / PERCENT_DENOMINATOR
        }();
        address pair = TomiSwapLibrary.pairFor(FACTORY, path[0], path[1]);
        _innerTransferWETH(
            pair,
            SafeMath.mul(amounts[0], SafeMath.sub(PERCENT_DENOMINATOR, percent)) / PERCENT_DENOMINATOR
        );
        _swap(amounts, path, to);

        IWETH(WETH).deposit{value: SafeMath.mul(amounts[0], percent) / PERCENT_DENOMINATOR}();
        _innerTransferWETH(pair, SafeMath.mul(amounts[0], percent) / PERCENT_DENOMINATOR);
        _swapFee(amounts, path, percent);
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    function _transferNotify(
        address from,
        address to,
        address token,
        uint256 amount
    ) internal {
        ITomiTransferListener(TRANSFER_LISTENER).transferNotify(from, to, token, amount);
    }

    function existPair(address tokenA, address tokenB) public view returns (bool) {
        return ITomiFactory(FACTORY).getPair(tokenA, tokenB) != address(0);
    }

    function getReserves(address tokenA, address tokenB) public view returns (uint256, uint256) {
        return TomiSwapLibrary.getReserves(FACTORY, tokenA, tokenB);
    }

    function pairFor(address tokenA, address tokenB) public view returns (address) {
        return TomiSwapLibrary.pairFor(FACTORY, tokenA, tokenB);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public view returns (uint256 amountOut) {
        uint256 percent = _getSwapFeePercent();
        uint256 amount = SafeMath.mul(amountIn, SafeMath.sub(PERCENT_DENOMINATOR, percent)) / PERCENT_DENOMINATOR;
        return TomiSwapLibrary.getAmountOut(amount, reserveIn, reserveOut);
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public view returns (uint256 amountIn) {
        uint256 percent = _getSwapFeePercent();
        uint256 amount = TomiSwapLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
        return SafeMath.mul(amount, PERCENT_DENOMINATOR) / SafeMath.sub(PERCENT_DENOMINATOR, percent);
    }

    function getAmountsOut(uint256 amountIn, address[] memory path) public view returns (uint256[] memory amounts) {
        uint256 percent = _getSwapFeePercent();
        return _getAmountsOut(amountIn, path, percent);
    }

    function getAmountsIn(uint256 amountOut, address[] memory path) public view returns (uint256[] memory amounts) {
        uint256 percent = _getSwapFeePercent();
        return _getAmountsIn(amountOut, path, percent);
    }

    function migrateLiquidity(address pair, address tokenA, address tokenB, address[] calldata users) external onlyOwner {
        if (ITomiFactory(FACTORY).getPair(tokenA, tokenB) == address(0)) {
            ITomiFactory(FACTORY).createPair(tokenA, tokenB);
        }
        address newPair = ITomiFactory(FACTORY).getPair(tokenA, tokenB);
        for(uint i = 0; i < users.length; i++) {
            uint liquidity = ITomiPair(pair).balanceOf(users[i]);
            if(liquidity > 0) {
                ITomiPair(pair).burn(users[i], newPair, liquidity);
                ITomiPair(newPair).mint(users[i]);
                ITomiFactory(FACTORY).addPlayerPair(users[i], newPair);
            }
        }

        ITomiTransferListener(TRANSFER_LISTENER).upgradeProdutivity(pair, newPair);    

    }
}
