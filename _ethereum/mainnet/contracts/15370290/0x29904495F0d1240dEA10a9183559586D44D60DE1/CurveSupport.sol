//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Strings.sol";
import "./SafeCast.sol";
import "./IERC20Metadata.sol";

import "./BaseSupport.sol";
import "./IProtocolSupport.sol";
import "./ICurve.sol";

contract CurveSupport is IProtocolSupport, BaseSupport {
    using SafeCast for uint256;

    struct SwapData {
        address _pool;
        address _from;
        int128 _index0;
        int128 _index1;
        bool _meta;
        uint256 _minReturn;
    }

    struct QuoteData {
        address _pool;
        address _from;
        address _to;
        uint256 _amount;
    }

    struct QuoteReturnData {
        int128 _index0;
        int128 _index1;
        bool _meta;
    }

    struct TokensQuoteData {
        address _pool;
        uint256 _amount;
    }

    struct TokensQuoteReturnData {
        int128 _index0;
        int128 _index1;
        address _to;
    }

    address public immutable crvBaseToken;
    // uint256 public immutable baseTokenAmount;
    address public immutable baseToken0;
    address public immutable baseToken1;
    address public immutable baseToken2;

    constructor(address _crvBaseToken, address[] memory _crvBasePoolTokens) {
        crvBaseToken = _crvBaseToken;
        baseToken0 = _crvBasePoolTokens[0];
        baseToken1 = _crvBasePoolTokens[1];
        baseToken2 = _crvBasePoolTokens[2];
    }

    function baseTokenAmount() public view returns (uint256 _index) {
        if (baseToken0 != address(0)) _index += 1;
        if (baseToken1 != address(0)) _index += 1;
        if (baseToken2 != address(0)) _index += 1;
    }

    function crvBasePoolTokens() public view returns (address[] memory) {
        uint256 _index = baseToken2 == address(0) ? 2 : 3;
        address[] memory _addresses = new address[](_index);
        _addresses[0] = baseToken0;
        _addresses[1] = baseToken1;
        if (_index == 3) _addresses[2] = baseToken2;
        return _addresses;
    }

    function crvBasePoolTokenIndex(address _address) public view returns (int128 _index) {
        if (_address == baseToken0) return int128(1);
        if (_address == baseToken1) return int128(2);
        if (_address == baseToken2) return int128(3);
    }

    function quote(bytes memory _inputData) external view override returns (uint256 _returns, bytes memory _returnData) {
        QuoteData memory _quoteData = abi.decode(_inputData, (QuoteData));
        QuoteReturnData memory _quoteReturnData;

        _quoteReturnData._meta = _getCrvCoins(_quoteData._pool, 1) == crvBaseToken;

        (int128 index0, int128 index1) = _getCrvCoinIndex(_quoteData._pool, _quoteData._from, _quoteData._to, _quoteReturnData._meta);

        if (index0 == 100) _quoteReturnData._index0 = crvBasePoolTokenIndex(_quoteData._from);
        if (index1 == 100) _quoteReturnData._index1 = crvBasePoolTokenIndex(_quoteData._to);

        if (_quoteReturnData._meta) {
            _returns = ICrvPool(_quoteData._pool).get_dy_underlying(_quoteReturnData._index0, _quoteReturnData._index1, _quoteData._amount);
        } else {
            _returns = ICrvPool(_quoteData._pool).get_dy(index0, index1, _quoteData._amount);
        }
        _returnData = abi.encode(_quoteReturnData);
    }

    ///@dev only index 0 token swap to one of 3pool
    function tokensQuote(bytes memory _inputData) external view override returns (uint256 _returns, bytes memory _returnData) {
        require(baseTokenAmount() != 0, "CurveSupport: crvBasePoolTokens length is 0");
        TokensQuoteData memory _quoteData = abi.decode(_inputData, (TokensQuoteData));
        TokensQuoteReturnData memory _quoteReturnData;

        uint256 _lastHandleAmount;
        for (uint256 _i = 1; _i <= baseTokenAmount(); _i++) {
            uint256 _returnAmount = ICrvPool(_quoteData._pool).get_dy_underlying(_toInt128(0), _toInt128(_i), _quoteData._amount);

            uint256 _handleAmount = _handleDecimals(crvBasePoolTokens()[_i - 1], _returnAmount);
            if (_handleAmount > _lastHandleAmount) {
                _returns = _returnAmount;
                _lastHandleAmount = _handleAmount;
                _quoteReturnData._index0 = _toInt128(0);
                _quoteReturnData._index1 = _toInt128(_i);
            }
        }
        _quoteReturnData._to = crvBasePoolTokens()[SafeCast.toUint256(_quoteReturnData._index1 - 1)];
        _returnData = abi.encode(_quoteReturnData);
    }

    function swap(uint256 _amount, bytes memory _inputData) external payable override returns (uint256 _returns) {
        SwapData memory _data = abi.decode(_inputData, (SwapData));
        _safeApprove(IERC20(_data._from), _data._pool, _amount);
        if (_data._meta) {
            _returns = ICrvPool(_data._pool).exchange_underlying(_data._index0, _data._index1, _amount, _data._minReturn);
        } else {
            _returns = ICrvPool(_data._pool).exchange(_data._index0, _data._index1, _amount, _data._minReturn);
        }
    }

    function _getCrvCoinIndex(
        address _pool,
        address _from,
        address _to,
        bool _meta
    ) private view returns (int128 index0, int128 index1) {
        uint256 a = 100;
        uint256 b = 100;
        for (uint256 i = 0; i < 4; i++) {
            bool success;
            bytes memory data;
            if (_meta) (success, data) = _pool.staticcall(abi.encodeWithSelector(bytes4(keccak256("coins(uint256)")), i));
            else (success, data) = _pool.staticcall(abi.encodeWithSelector(bytes4(keccak256("coins(int128)")), SafeCast.toInt128(i.toInt256())));

            if (success) {
                if (abi.decode(data, (address)) == _from) a = i;
                if (abi.decode(data, (address)) == _to) b = i;
            }
        }

        index0 = SafeCast.toInt128(a.toInt256());
        index1 = SafeCast.toInt128(b.toInt256());
    }

    function _getCrvCoins(address _pool, uint256 _index) private view returns (address) {
        bool success;
        bytes memory data;
        (success, data) = _pool.staticcall(abi.encodeWithSelector(bytes4(keccak256("coins(uint256)")), _index));
        if (!success) {
            (success, data) = _pool.staticcall(abi.encodeWithSelector(bytes4(keccak256("coins(int128)")), SafeCast.toInt128(_index.toInt256())));
        }
        return abi.decode(data, (address));
    }

    function _toInt128(uint256 _a) private pure returns (int128) {
        return SafeCast.toInt128(_a.toInt256());
    }

    function _toUint256(int128 _a) private pure returns (uint256) {
        return uint256(int256(_a));
    }
}
