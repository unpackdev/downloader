//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./SafeCast.sol";

import "./BaseSupport.sol";
import "./IProtocolSupport.sol";
import "./IUniswap.sol";

contract UniV3Support is BaseSupport, IProtocolSupport {
    using SafeMath for uint256;

    struct UniSwapData {
        address _pool;
        address _from;
        address _to;
    }

    struct QuoteData {
        address _from;
        address _to;
        uint256 _amount;
    }

    struct QuoteReturnData {
        address _pool;
    }

    struct TokensQuoteData {
        address _from;
        address[] _tos;
        uint256 _amount;
    }

    struct TokensQuoteReturnData {
        address _pool;
        address _to;
    }

    uint24 private constant V3_FEE_EXTRA_LOW = 100;
    uint24 private constant V3_FEE_LOW = 500;
    uint24 private constant V3_FEE_MEDIUM = 3000;
    uint24 private constant V3_FEE_HIGH = 10000;

    uint160 private constant UNI3_MIN_AMOUNT = 4295128739 + 1;
    uint160 private constant UNI3_MAX_AMOUNT = 1461446703485210103287273052203988822378723970342 - 1;

    address public immutable uniV3Factory;
    address public immutable uniV3Quoter;

    constructor(address _uniV3Factory, address _uniV3Quoter) {
        uniV3Factory = _uniV3Factory;
        uniV3Quoter = _uniV3Quoter;
    }

    function quote(bytes memory _inputData) external override returns (uint256, bytes memory) {
        QuoteData memory _data = abi.decode(_inputData, (QuoteData));

        (address _pool, uint256 _returns) = _quote(_data._from, _data._to, _data._amount);
        return (_returns, abi.encode(QuoteReturnData({ _pool: _pool })));
    }

    function tokensQuote(bytes memory _inputData) external override returns (uint256 _returns, bytes memory _returnData) {
        TokensQuoteData memory _data = abi.decode(_inputData, (TokensQuoteData));
        TokensQuoteReturnData memory _quoteReturnData;
        uint256 _lastHandleAmount;
        for (uint256 i = 0; i < _data._tos.length; i++) {
            address _to1 = _data._tos[i];
            (address _pool, uint256 _returnAmount) = _quote(_data._from, _to1, _data._amount);

            if (_returnAmount > 0) {
                uint256 _handleAmount = _handleDecimals(_to1, _returnAmount);
                if (_handleAmount > _lastHandleAmount) {
                    _quoteReturnData._to = _to1;
                    _returns = _returnAmount;
                    _lastHandleAmount = _handleAmount;
                    _quoteReturnData._pool = _pool;
                }
            }
        }
        _returnData = abi.encode(_quoteReturnData);
    }

    function swap(uint256 _amount, bytes memory _inputData) external payable override returns (uint256 _returns) {
        UniSwapData memory _data = abi.decode(_inputData, (UniSwapData));
        bool _zeroForOne = _data._from < _data._to;
        IUni3Pool _pool = IUni3Pool(_data._pool);
        (int256 amount0, int256 amount1) = _pool.swap(
            address(this),
            _zeroForOne,
            SafeCast.toInt256(_amount),
            _zeroForOne ? UNI3_MIN_AMOUNT : UNI3_MAX_AMOUNT,
            abi.encode(_data._from, _amount, _pool.token0(), _pool.token1(), _pool.fee())
        );
        return _zeroForOne ? SafeCast.toUint256(-amount1) : SafeCast.toUint256(-amount0);
    }

    function uniswapV3SwapCallback(
        int256,
        int256,
        bytes memory data
    ) external {
        (address _token, uint256 _amount, address _token0, address _token1, uint24 _fee) = abi.decode(data, (address, uint256, address, address, uint24));
        address _pool = IUniFactory(uniV3Factory).getPool(_token0, _token1, _fee);
        require(msg.sender == _pool, "UniSupport: uniswapV3SwapCallback sender not is _pool");
        SafeERC20.safeTransfer(IERC20(_token), _pool, _amount);
    }

    function _quote(
        address _from,
        address _to,
        uint256 _amount
    ) private returns (address _pool, uint256 _returns) {
        for (uint256 i = 0; i < _getFees().length; i++) {
            address _pool1 = IUniFactory(uniV3Factory).getPool(_from, _to, _getFees()[i]);

            if (_pool1 != address(0)) {
                bytes memory _path = abi.encodePacked(_from, _getFees()[i], _to);
                try IQuoter(uniV3Quoter).quoteExactInput(_path, _amount) returns (uint256 _maxReturn) {
                    if (_maxReturn > _returns) {
                        _returns = _maxReturn;
                        _pool = _pool1;
                    }
                } catch (bytes memory) {
                    continue;
                }
            }
        }
    }

    function _getFees() private pure returns (uint24[] memory) {
        uint24[] memory fees = new uint24[](4);
        fees[0] = V3_FEE_EXTRA_LOW;
        fees[1] = V3_FEE_LOW;
        fees[2] = V3_FEE_MEDIUM;
        fees[3] = V3_FEE_HIGH;
        return fees;
    }
}
