// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./FAave.sol";

function _isAaveLiquid(address _debtToken, uint256 _debtAmt)
    view
    returns (bool)
{
    return _isAaveUnderlyingLiquid(_debtToken, _debtAmt);
}
