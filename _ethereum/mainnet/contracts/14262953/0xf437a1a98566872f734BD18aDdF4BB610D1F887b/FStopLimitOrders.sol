// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "./FUniswapGeneral.sol";
import "./Tokens.sol";

function _canHandleStopLimitOrder(
    address _inToken,
    address _outToken,
    uint256 _amountIn,
    uint256 _minReturn,
    address _uniRouter,
    address _wrappedNative,
    bytes calldata _data
) view returns (bool) {
    (bytes memory _auxData, uint256 _maxReturn) = abi.decode(
        _data,
        (bytes, uint256)
    );

    (, , uint256 fee, address[] memory path, address[] memory feePath) = abi
        .decode(_auxData, (address, address, uint256, address[], address[]));

    if (_inToken == _wrappedNative || _inToken == NATIVE) {
        if (_amountIn <= fee) return false;
        uint256 bought = _getAmountOut(_amountIn - fee, path, _uniRouter);
        return bought <= _maxReturn && bought >= _minReturn;
    } else if (_outToken == _wrappedNative || _outToken == NATIVE) {
        uint256 bought = _getAmountOut(_amountIn, path, _uniRouter);
        if (bought <= fee) return false;
        return bought - fee <= _maxReturn && bought - fee >= _minReturn;
    } else {
        uint256 inTokenFee = _getAmountIn(fee, feePath, _uniRouter);
        if (inTokenFee >= _amountIn) return false;
        uint256 bought = _getAmountOut(
            _amountIn - inTokenFee,
            path,
            _uniRouter
        );
        return bought <= _maxReturn && bought >= _minReturn;
    }
}
