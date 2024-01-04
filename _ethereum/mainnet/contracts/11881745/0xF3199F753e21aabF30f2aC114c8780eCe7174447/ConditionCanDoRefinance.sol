// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./GelatoConditionsStandard.sol";
import "./FGelatoDebtBridge.sol";
import "./CDebtBridge.sol";
import "./GelatoBytes.sol";
import "./SDebtBridge.sol";
import "./FMaker.sol";
import "./FGelatoDebtBridge.sol";
import "./CTokens.sol";
import "./IInstaFeeCollector.sol";

contract ConditionCanDoRefinance is GelatoConditionsStandard {
    address public immutable instaFeeCollector;
    address public immutable oracleAggregator;

    constructor(address _instaFeeCollector, address _oracleAggregator) {
        instaFeeCollector = _instaFeeCollector;
        oracleAggregator = _oracleAggregator;
    }

    function getConditionData(
        address _dsa,
        uint256 _fromVaultId,
        address _colToken,
        uint256 _makerDestVaultId,
        string calldata _makerDestColType
    ) public pure virtual returns (bytes memory) {
        return
            abi.encodeWithSelector(
                this.canDoRefinance.selector,
                _dsa,
                _fromVaultId,
                _colToken,
                _makerDestVaultId,
                _makerDestColType
            );
    }

    function ok(
        uint256,
        bytes calldata _conditionData,
        uint256
    ) public view virtual override returns (string memory) {
        (
            address _dsa,
            uint256 _fromVaultId,
            address _colToken,
            uint256 _makerDestVaultId,
            string memory _makerDestColType
        ) =
            abi.decode(
                _conditionData[4:],
                (address, uint256, address, uint256, string)
            );

        return
            canDoRefinance(
                _dsa,
                _fromVaultId,
                _colToken,
                _makerDestVaultId,
                _makerDestColType
            );
    }

    function canDoRefinance(
        address _dsa,
        uint256 _fromVaultId,
        address _colToken,
        uint256 _makerDestVaultId,
        string memory _makerDestColType
    ) public view returns (string memory) {
        uint256 debtAmt = _getRealisedDebt(_getMakerVaultDebt(_fromVaultId));
        return
            _getDebtBridgeRoute(
                DebtBridgeInputData({
                    dsa: _dsa,
                    colAmt: _getMakerVaultCollateralBalance(_fromVaultId),
                    colToken: _colToken,
                    debtAmt: debtAmt,
                    oracleAggregator: oracleAggregator,
                    makerDestVaultId: _makerDestVaultId,
                    makerDestColType: _makerDestColType,
                    fees: IInstaFeeCollector(instaFeeCollector).fee(),
                    flashRoute: _getFlashLoanRoute(DAI, _fromVaultId, debtAmt)
                })
            ) != PROTOCOL.NONE
                ? OK
                : "CannotDoRefinance";
    }
}
