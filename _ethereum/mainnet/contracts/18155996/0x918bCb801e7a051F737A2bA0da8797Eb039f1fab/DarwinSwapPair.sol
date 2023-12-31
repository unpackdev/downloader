pragma solidity ^0.8.14;

import "./DarwinSwapERC20.sol";

import "./IDarwinSwapPair.sol";
import "./IERC20.sol";
import "./IDarwinSwapFactory.sol";
import "./IDarwinSwapCallee.sol";

import "./Math.sol";
import "./Tokenomics2Library.sol";

contract DarwinSwapPair is IDarwinSwapPair, DarwinSwapERC20 {
    uint public constant MINIMUM_LIQUIDITY = 10 ** 3;
    bytes4 private constant _SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public liquidityInjector;

    address public factory;
    address public router;
    address public token0;
    address public token1;

    uint256 private _reserve0; // uses single storage slot, accessible via getReserves
    uint256 private _reserve1; // uses single storage slot, accessible via getReserves
    uint32 private _blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // _reserve0 * _reserve1, as of immediately after the most recent liquidity event

    uint private _unlocked = 1;

    event ProtocolFeesLPTokensMinted(address indexed reciever, uint256 amount);

    modifier lock() {
        require(_unlocked == 1, "DarwinSwap: LOCKED");
        _unlocked = 0;
        _;
        _unlocked = 1;
    }

    modifier onlyLiquidityInjector() {
        require(
            msg.sender == liquidityInjector,
            "DarwinSwapPair: CALLER_NOT_ANTIDUMP"
        );
        _;
    }

    function getReserves()
        public
        view
        returns (uint256 reserve0, uint256 reserve1, uint32 blockTimestampLast)
    {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
        blockTimestampLast = _blockTimestampLast;
    }

    function _safeTransfer(
        address token,
        address to,
        uint value,
        address otherToken
    ) private {
        // NOTE: DarwinSwap: TOKS1_BUY
        if (otherToken != address(0)) {
            value -= Tokenomics2Library.handleToks1Buy(
                token,
                value,
                otherToken,
                factory
            );
        }
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(_SELECTOR, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "DarwinSwap: TRANSFER_FAILED"
        );
    }

    constructor() {
        factory = msg.sender;
        router = IDarwinSwapFactory(factory).router();
    }

    // called once by the factory at time of deployment
    function initialize(
        address _token0,
        address _token1,
        address _liquidityInjector
    ) external {
        require(msg.sender == factory, "DarwinSwap: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;
        liquidityInjector = _liquidityInjector;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint balance0,
        uint balance1,
        uint256 reserve0,
        uint256 reserve1
    ) private {
        require(
            balance0 <= type(uint256).max && balance1 <= type(uint256).max,
            "DarwinSwap: OVERFLOW"
        );
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed = blockTimestamp - _blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && reserve0 != 0 && reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += (reserve1 / reserve0) * timeElapsed;
            price1CumulativeLast += (reserve0 / reserve1) * timeElapsed;
        }
        _reserve0 = uint256(balance0);
        _reserve1 = uint256(balance1);
        _blockTimestampLast = blockTimestamp;
        emit Sync(_reserve0, _reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/2th of the growth in sqrt(k) to feeTo
    // and mint 1/6th to liquidityBundles contract
    // function _mintFee(
    //     uint256 reserve0,
    //     uint256 reserve1
    // ) private returns (bool feeOn) {
    //     address feeTo = IDarwinSwapFactory(factory).feeTo();
    //     feeOn = feeTo != address(0);
    //     uint _kLast = kLast; // gas savings
    //     if (feeOn) {
    //         if (_kLast != 0) {
    //             uint rootK = Math.sqrt(reserve0 * reserve1);
    //             uint rootKLast = Math.sqrt(_kLast);
    //             if (rootK > rootKLast) {
    //                 {
    //                     uint numerator = totalSupply() * (rootK - rootKLast);
    //                     uint denominator = rootK + rootKLast;
    //                     uint liquidity = numerator / denominator;
    //                     if (liquidity > 0) {
    //                         _mint(feeTo, liquidity);
    //                         emit ProtocolFeesLPTokensMinted(feeTo, liquidity);
    //                     }
    //                 }
    //                 {
    //                     uint numerator = totalSupply() * (rootK - rootKLast);
    //                     uint denominator = rootK + rootKLast * 5;
    //                     uint liquidity = numerator / denominator;
    //                     if (liquidity > 0) {
    //                         _mint(
    //                             address(
    //                                 IDarwinSwapFactory(factory)
    //                                     .liquidityBundles()
    //                             ),
    //                             liquidity
    //                         );
    //                         emit ProtocolFeesLPTokensMinted(
    //                             address(
    //                                 IDarwinSwapFactory(factory)
    //                                     .liquidityBundles()
    //                             ),
    //                             liquidity
    //                         );
    //                     }
    //                 }
    //             }
    //         }
    //     } else if (_kLast != 0) {
    //         kLast = 0;
    //     }
    // }

    event KLastDifferentThanZero();
    event FeesAreOn();
    event RootKGreaterThanRootKLast();
    event LiquidityGreaterThanZero();

    function _mintFee(
        uint256 _reserve0Call,
        uint256 _reserve1Call
    ) private returns (bool feeOn) {
        address feeTo = IDarwinSwapFactory(factory).feeTo();
        feeOn = true;
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            emit FeesAreOn();
            if (_kLast != 0) {
                emit KLastDifferentThanZero();
                uint rootK = Math.sqrt(_reserve0Call * _reserve1Call);
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    emit RootKGreaterThanRootKLast();
                    uint numerator = totalSupply() * (rootK - rootKLast) * 8;
                    uint denominator = rootK * 17 + rootKLast * 8;
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) {
                        _mint(feeTo, liquidity);
                        emit ProtocolFeesLPTokensMinted(feeTo, liquidity);
                    }
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    event KLastEventPart(uint256 reserve0, uint256 reserve1);
    event KLastChanged(uint256 _kLast);

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint liquidity) {
        (uint256 reserve0, uint256 reserve1, ) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0 - reserve0;
        uint amount1 = balance1 - reserve1;

        bool feeOn = true;
        uint totSupply = totalSupply(); // gas savings, must be defined here since totalSupply() can update in _mintFee
        if (totSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(
                (amount0 * totSupply) / reserve0,
                (amount1 * totSupply) / reserve1
            );
        }
        require(liquidity > 0, "DarwinSwap: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1, reserve0, reserve1);
        kLast = _reserve0 * _reserve1; // reserve0 and reserve1 are up-to-date

        emit KLastEventPart(_reserve0, _reserve1);
        emit KLastChanged(kLast);
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(
        address to
    ) external lock returns (uint amount0, uint amount1) {
        (uint256 reserve0, uint256 reserve1, ) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(reserve0, reserve1);
        uint totSupply = totalSupply(); // gas savings, must be defined here since totalSupply() can update in _mintFee
        amount0 = (liquidity * balance0) / totSupply; // using balances ensures pro-rata distribution
        amount1 = (liquidity * balance1) / totSupply; // using balances ensures pro-rata distribution
        // require(amount0 > 0 && amount1 > 0, "DarwinSwap: INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0, address(0));
        _safeTransfer(_token1, to, amount1, address(0));
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, reserve0, reserve1);
        if (feeOn) kLast = _reserve0 * _reserve1; // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data,
        address[2] memory firstAndLastInPath
    ) external lock {
        require(msg.sender == router, "DarwinSwap::swap: FORBIDDEN");
        require(
            amount0Out > 0 || amount1Out > 0,
            "DarwinSwap: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        (uint256 reserve0, uint256 reserve1, ) = getReserves(); // gas savings
        require(
            amount0Out < reserve0 && amount1Out < reserve1,
            "DarwinSwap: INSUFFICIENT_LIQUIDITY"
        );

        uint balance0;
        uint balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "DarwinSwap: INVALID_TO");
            if (amount0Out > 0)
                _safeTransfer(_token0, to, amount0Out, firstAndLastInPath[0]); // optimistically transfer tokens
            if (amount1Out > 0)
                _safeTransfer(_token1, to, amount1Out, firstAndLastInPath[0]); // optimistically transfer tokens
            if (data.length > 0)
                IDarwinSwapCallee(to).darwinSwapCall(
                    msg.sender,
                    amount0Out,
                    amount1Out,
                    data
                );
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > reserve0 - amount0Out
            ? balance0 - (reserve0 - amount0Out)
            : 0;
        uint amount1In = balance1 > reserve1 - amount1Out
            ? balance1 - (reserve1 - amount1Out)
            : 0;
        require(
            amount0In > 0 || amount1In > 0,
            "DarwinSwap: INSUFFICIENT_INPUT_AMOUNT"
        );
        /* { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = balance0 * 1000 - amount0In * 3;
        uint balance1Adjusted = balance1 * 1000 - amount1In * 3;
        require(balance0Adjusted * balance1Adjusted >= reserve0 * reserve1 * (1000**2), "DarwinSwap: K");
        } */

        if (firstAndLastInPath[1] != address(0)) {
            // NOTE: TOKS2_SELL
            Tokenomics2Library.handleToks2Sell(
                amount0In > 0 ? token0 : token1,
                amount0In > amount1In ? amount0In : amount1In,
                firstAndLastInPath[1],
                factory
            );
            balance0 = IERC20(token0).balanceOf(address(this));
            balance1 = IERC20(token1).balanceOf(address(this));
        }
        if (firstAndLastInPath[0] != address(0)) {
            // NOTE: TOKS2_BUY
            Tokenomics2Library.handleToks2Buy(
                amount0Out > 0 ? token0 : token1,
                amount0Out > amount1Out ? amount0Out : amount1Out,
                firstAndLastInPath[0],
                to,
                factory
            );
            balance0 = IERC20(token0).balanceOf(address(this));
            balance1 = IERC20(token1).balanceOf(address(this));
        }

        _update(balance0, balance1, reserve0, reserve1);
        _emitSwap(amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // NOTE: This emits the Swap event. Separate from swap() to avoid stack too deep errors.
    function _emitSwap(
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address to
    ) internal {
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // Allows liqInj guard to call this simpler swap function to spend less gas
    function swapWithoutToks(
        address tokenIn,
        uint amountIn
    ) external lock onlyLiquidityInjector {
        (uint reserveIn, uint reserveOut, address tokenOut) = token0 == tokenIn
            ? (_reserve0, _reserve1, token1)
            : (_reserve1, _reserve0, token0);
        uint amountOut = DarwinSwapLibrary.getAmountOut(
            amountIn,
            reserveIn,
            reserveOut
        );
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(msg.sender, amountOut);

        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            _reserve0,
            _reserve1
        );
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(
            _token0,
            to,
            IERC20(_token0).balanceOf(address(this)) - _reserve0,
            address(0)
        );
        _safeTransfer(
            _token1,
            to,
            IERC20(_token1).balanceOf(address(this)) - _reserve1,
            address(0)
        );
    }

    // force reserves to match balances
    function sync() external lock {
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            _reserve0,
            _reserve1
        );
    }

    // Overrides totalSupply to include also the liquidityInjector liquidity
    function totalSupply() public view override returns (uint) {
        return _totalSupply;
        /* uint _baseSupply = _totalSupply;
        if (_reserve0 == 0 || _reserve1 == 0) {
            return _baseSupply;
        }
        uint liqInjReserve0 = IERC20(token0).balanceOf(liquidityInjector);
        uint liqInjReserve1 = IERC20(token1).balanceOf(liquidityInjector);
        uint _liqInjLiq = Math.min((liqInjReserve0 * _totalSupply) / _reserve0, (liqInjReserve1 * _totalSupply) / _reserve1);
        return _baseSupply + _liqInjLiq; */
    }
}
