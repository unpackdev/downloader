// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "./FUniswapGeneral.sol";
import "./FHandlerUtils.sol";
import "./Tokens.sol";

function _canHandleLimitOrder(
    address thisContractAddress,
    address _inToken,
    address _outToken,
    uint256 _amountIn,
    uint256 _minReturn,
    address _uniRouter,
    address _wrappedNative,
    bytes calldata _data
) view returns (bool) {
    (
        ,
        address[] memory path,
        ,
        uint256 fee,
        address[] memory feePath
    ) = _handleInputData(thisContractAddress, _inToken, _outToken, _data);

    if (_inToken == _wrappedNative || _inToken == NATIVE) {
        if (_amountIn <= fee) return false;
        return _getAmountOut(_amountIn - fee, path, _uniRouter) >= _minReturn;
    } else if (_outToken == _wrappedNative || _outToken == NATIVE) {
        uint256 bought = _getAmountOut(_amountIn, path, _uniRouter);
        if (bought <= fee) return false;
        return bought - fee >= _minReturn;
    } else {
        uint256 inTokenFee = _getAmountIn(fee, feePath, _uniRouter);
        if (inTokenFee >= _amountIn) return false;
        return
            _getAmountOut(_amountIn - inTokenFee, path, _uniRouter) >=
            _minReturn;
    }
}
