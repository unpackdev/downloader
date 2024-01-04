// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./FMaker.sol";

function _isDebtAmtDust(
    address _dsa,
    uint256 _destVaultId,
    string memory _destColType,
    uint256 _daiDebtAmt
) view returns (bool) {
    _destVaultId = _isVaultOwner(_destVaultId, _dsa) ? _destVaultId : 0;

    return _isDebtAmtDustExplicit(_destVaultId, _destColType, _daiDebtAmt);
}

function _isDebtAmtDustExplicit(
    uint256 _destVaultId,
    string memory _destColType,
    uint256 _daiDebtAmt
) view returns (bool) {
    return
        _destVaultId == 0
            ? _debtIsDustNewVault(_destColType, _daiDebtAmt)
            : _debtIsDust(_destVaultId, _daiDebtAmt);
}
