// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./FCompound.sol";

function _cTokenHasLiquidity(address _debtToken, uint256 _debtAmt)
    view
    returns (bool)
{
    return _isCompoundUnderlyingLiquidity(_debtToken, _debtAmt);
}
