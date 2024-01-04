// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./FMaker.sol";

function _destVaultWillBeSafe(
    address _dsa,
    uint256 _destVaultId,
    string memory _destColType,
    uint256 _colAmt,
    uint256 _daiDebtAmt
) view returns (bool) {
    _destVaultId = _isVaultOwner(_destVaultId, _dsa) ? _destVaultId : 0;

    return
        _destVaultWillBeSafeExplicit(
            _destVaultId,
            _destColType,
            _colAmt,
            _daiDebtAmt
        );
}

function _destVaultWillBeSafeExplicit(
    uint256 _destVaultId,
    string memory _destColType,
    uint256 _colAmt,
    uint256 _daiDebtAmt
) view returns (bool) {
    return
        _destVaultId == 0
            ? _newVaultWillBeSafe(_destColType, _colAmt, _daiDebtAmt)
            : _vaultWillBeSafe(_destVaultId, _colAmt, _daiDebtAmt);
}
