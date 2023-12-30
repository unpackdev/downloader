pragma solidity =0.7.2;

// SPDX-License-Identifier: UNLICENSED

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function sync() external;
}

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
}

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

contract FlashCycle2 is IUniswapV2Callee {

    address payable owner;
    IUniswapV2Router02 constant uniswapV2Router02 = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    constructor() {
        owner = msg.sender;
    }

    function _sortTokens(address tokenA, address tokenB) private pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    function _pairFor(address tokenA, address tokenB) private pure returns (address pair) {
        (address token0, address token1) = _sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                uniswapV2Router02.factory(),
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) private {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = _sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(_pairFor(input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = _safeBalanceOf(input, address(pair)) - reserveInput;
            amountOutput = uniswapV2Router02.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? _pairFor(output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function _safeBalanceOf(address token, address who) private view returns (uint) {
        (bool success, bytes memory returnData) = token.staticcall(abi.encodeWithSignature("balanceOf(address)", who));
        if (success && returnData.length == 32) {
            return abi.decode(returnData, (uint));
        } else {
            return 0;
        }
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {

        address[] memory _path = abi.decode(data, (address[]));
        uint _amountOut        = amount0 + amount1;
        IUniswapV2Pair _pair0  = IUniswapV2Pair(msg.sender);
        address _pair1         = _pairFor(_path[0], _path[1]);

        (address _t0, address _t1)                           = (_pair0.token0(), _pair0.token1());
        (uint _r0, uint _r1,)                                = _pair0.getReserves();
        (address _tIn, address _tOut, uint _rIn, uint _rOut) =
            _path[0] == _t1 ? (_t0, _t1, _r0, _r1) : (_t1, _t0, _r1, _r0);

        uint _payback  = uniswapV2Router02.getAmountIn(_amountOut, _rIn, _rOut);
        uint _discount = _safeBalanceOf(_tIn, address(_pair0)) - _rIn;
        _payback = _discount <= _payback ? _payback - _discount : 0;

        IERC20(_tOut).transfer(_pair1, _safeBalanceOf(_tOut, address(this)));
        _swapSupportingFeeOnTransferTokens(_path, address(this));
        if (_payback > 0) {
            IERC20(_tIn).transfer(msg.sender, _payback);
        }

        uint _profit = _safeBalanceOf(_tIn, address(this));
        require(_profit > 0, "no profit");
        IERC20(_tIn).transfer(owner, _profit);
    }

    function cycle(uint investment, address[] calldata path) external {

        // sync all pairs in the path with lower balance than reserve
        for (uint i; i <= path.length - 2; i++) {
            IUniswapV2Pair _pair = IUniswapV2Pair(_pairFor(path[i], path[i + 1]));
            (uint112 _r0, uint112 _r1,) = _pair.getReserves();
            require(_r0 > 0 && _r1 > 0, "pair without liquidity");

            uint _b0 = _safeBalanceOf(_pair.token0(), address(_pair));
            uint _b1 = _safeBalanceOf(_pair.token1(), address(_pair));
            if (_b0 < _r0 || _b1 < _r1) {
                _pair.sync();
            }
        }

        IUniswapV2Pair _pair    = IUniswapV2Pair(_pairFor(path[0], path[1]));
        (uint _r0, uint _r1,)   = _pair.getReserves();
        (uint _rIn, uint _rOut) = path[0] == _pair.token0() ? (_r0, _r1) : (_r1, _r0);
        uint _aOut              = uniswapV2Router02.getAmountOut(investment, _rIn, _rOut);
        (uint _a0, uint _a1)    = path[0] == _pair.token0() ? (uint(0), _aOut) : (_aOut, uint(0));

        address[] memory _path = new address[](path.length - 1);
        for (uint i = 1; i < path.length; i++) {
            _path[i - 1] = path[i];
        }

        _pair.swap(_a0, _a1, address(this), abi.encode(_path));
    }
}