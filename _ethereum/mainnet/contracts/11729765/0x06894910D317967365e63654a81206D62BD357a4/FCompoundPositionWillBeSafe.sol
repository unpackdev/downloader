// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./CTokens.sol";
import "./FCompound.sol";

function _compoundPositionWillBeSafe(
    address _dsa,
    uint256 _colAmt,
    address _debtToken,
    uint256 _debtAmt
) view returns (bool) {
    return
        _wouldCompoundAccountBeLiquid(
            _dsa,
            _colAmt,
            _getCToken(_debtToken),
            _debtAmt
        );
}
