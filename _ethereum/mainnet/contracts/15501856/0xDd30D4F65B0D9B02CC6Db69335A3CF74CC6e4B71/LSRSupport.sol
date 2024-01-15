//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./SafeCast.sol";

import "./BaseSupport.sol";
import "./IProtocolSupport.sol";
import "./ILSR.sol";

contract LSRSupport is BaseSupport, IProtocolSupport {
    using SafeMath for uint256;

    struct LSRData {
        address _LSR;
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

    ILSRFactory public immutable LSRFactory;

    constructor(address _LSRFactory) {
        LSRFactory = ILSRFactory(_LSRFactory);
    }

    function quote(bytes memory _inputData) external override returns (uint256, bytes memory) {
        QuoteData memory _data = abi.decode(_inputData, (QuoteData));

        (uint256 _returns, address _pool) = _quote(_data._from, _data._to, _data._amount);
        return (_returns, abi.encode(QuoteReturnData({ _pool: _pool })));
    }

    function _quote(
        address _from,
        address _to,
        uint256 _amount
    ) private returns (uint256 _returns, address _pool) {
        _pool = _getLSROfToken(_from, _to);
        if (_pool == address(0)) return (0, address(0));

        ILSR _LSR = ILSR(_pool);

        ILSRStrategy _strategy = ILSRStrategy(_LSR.strategy());
        bool _order = _from == _LSR.mpr();

        ///@dev buy msd
        if (_order) {
            if (_strategy.depositStatus()) return (0, address(0));
            if (_strategy.limitOfDeposit() < _amount) return (0, address(0));

            _returns = _LSR.getAmountToBuy(_amount);

            if (_LSR.msdQuota() < _returns) return (0, address(0));
        } else {
            if (_strategy.withdrawStatus()) return (0, address(0));

            _returns = _LSR.getAmountToSell(_amount);
            if (_LSR.mprOutstanding() < _returns) return (0, address(0));
        }
    }

    function tokensQuote(bytes memory _inputData) external override returns (uint256 _returns, bytes memory _returnData) {
        TokensQuoteData memory _quoteData = abi.decode(_inputData, (TokensQuoteData));
        TokensQuoteReturnData memory _quoteReturnData;
        uint256 _lastHandleAmount;
        for (uint256 i = 0; i < _quoteData._tos.length; i++) {
            address _to1 = _quoteData._tos[i];

            (uint256 _returns1, address _LSR) = _quote(_quoteData._from, _to1, _quoteData._amount);

            uint256 _handleAmount = _handleDecimals(_to1, _returns1);
            if (_handleAmount > _lastHandleAmount) {
                _quoteReturnData._to = _to1;
                _returns = _returns1;
                _lastHandleAmount = _handleAmount;
                _quoteReturnData._pool = _LSR;
            }
        }
        _returnData = abi.encode(_quoteReturnData);
    }

    function swap(uint256 _amount, bytes memory _inputData) external payable override returns (uint256) {
        LSRData memory _data = abi.decode(_inputData, (LSRData));
        (uint256 _returns, address _LSR) = _quote(_data._from, _data._to, _amount);

        bool _order = _data._from == ILSR(_LSR).mpr();

        _safeApprove(IERC20(_data._from), _LSR, _amount);
        if (_order) ILSR(_LSR).buyMsd(_amount);
        else ILSR(_LSR).sellMsd(_amount);
        return _returns;
    }

    function _getLSROfToken(address _from, address _to) private view returns (address _LSR) {
        (address[] memory _allLSRs, address[] memory _msds, address[] memory _mprs) = LSRFactory.getAllLSRs();
        for (uint256 _i = 0; _i < _allLSRs.length; _i++) {
            if ((_mprs[_i] == _from && _msds[_i] == _to) || (_mprs[_i] == _to && _msds[_i] == _from)) {
                _LSR = _allLSRs[_i];
                break;
            }
        }
    }
}
