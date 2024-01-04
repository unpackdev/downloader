// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./FAaveHasLiquidity.sol";
import "./FAavePositionWillBeSafe.sol";
import "./FIsDebtAmtDust.sol";
import "./FDebtCeilingIsReached.sol";
import "./FDestVaultWillBeSafe.sol";
import "./FCompoundHasLiquidity.sol";
import "./FCompoundPositionWillBeSafe.sol";
import "./SDebtBridge.sol";
import "./CTokens.sol";
import "./FGelatoDebtBridge.sol";

function _canDoMakerToAaveDebtBridge(DebtBridgeInputData memory _data)
    view
    returns (bool)
{
    _data.debtAmt = _getMaxAmtToBorrow(
        _data.debtAmt,
        _getGasCostMakerToAave(_data.flashRoute),
        _data.fees,
        _data.oracleAggregator
    );
    return
        _isAaveLiquid(DAI, _data.debtAmt) &&
        _aavePositionWillBeSafe(
            _data.dsa,
            _data.colAmt,
            _data.colToken,
            _data.debtAmt,
            _data.oracleAggregator
        );
}

function _canDoMakerToMakerDebtBridge(DebtBridgeInputData memory _data)
    view
    returns (bool)
{
    _data.debtAmt = _getMaxAmtToBorrow(
        _data.debtAmt,
        _getGasCostMakerToMaker(_data.makerDestVaultId == 0, _data.flashRoute),
        _data.fees,
        _data.oracleAggregator
    );
    return
        !_isDebtAmtDust(
            _data.dsa,
            _data.makerDestVaultId,
            _data.makerDestColType,
            _data.debtAmt
        ) &&
        !_isDebtCeilingReached(
            _data.dsa,
            _data.makerDestVaultId,
            _data.makerDestColType,
            _data.debtAmt
        ) &&
        _destVaultWillBeSafe(
            _data.dsa,
            _data.makerDestVaultId,
            _data.makerDestColType,
            _data.colAmt,
            _data.debtAmt
        );
}

function _canDoMakerToCompoundDebtBridge(DebtBridgeInputData memory _data)
    view
    returns (bool)
{
    _data.debtAmt = _getMaxAmtToBorrow(
        _data.debtAmt,
        _getGasCostMakerToCompound(_data.flashRoute),
        _data.fees,
        _data.oracleAggregator
    );
    return
        _cTokenHasLiquidity(DAI, _data.debtAmt) &&
        _compoundPositionWillBeSafe(
            _data.dsa,
            _data.colAmt,
            DAI,
            _data.debtAmt
        );
}
