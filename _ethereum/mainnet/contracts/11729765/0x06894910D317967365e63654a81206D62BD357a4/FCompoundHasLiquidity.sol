// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./ICToken.sol";
import "./FCompound.sol";

function _cTokenHasLiquidity(address _debtToken, uint256 _debtAmt)
    view
    returns (bool)
{
    return ICToken(_getCToken(_debtToken)).getCash() > _debtAmt;
}
