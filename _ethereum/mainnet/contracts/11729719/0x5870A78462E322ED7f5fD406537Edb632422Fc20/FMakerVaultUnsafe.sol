// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./DSMath.sol";
import "./IInstaMakerResolver.sol";
import "./GelatoBytes.sol";
import "./CInstaDapp.sol";

function _isVaultUnsafe(
    uint256 _vaultId,
    address _priceOracle,
    bytes memory _oraclePayload,
    uint256 _minColRatio
) view returns (bool) {
    (bool success, bytes memory returndata) =
        _priceOracle.staticcall(_oraclePayload);

    if (!success) {
        GelatoBytes.revertWithError(
            returndata,
            "ConditionMakerVaultUnsafe.isVaultUnsafe:oracle:"
        );
    }

    uint256 colPrice = abi.decode(returndata, (uint256));

    IInstaMakerResolver.VaultData memory vault =
        IInstaMakerResolver(INSTA_MAKER_RESOLVER).getVaultById(_vaultId);

    uint256 colRatio = wdiv(wmul(vault.collateral, colPrice), vault.debt);

    return colRatio < _minColRatio;
}
