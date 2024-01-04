// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./GelatoConditionsStandard.sol";
import "./FAavePositionWillBeSafe.sol";
import "./FMaker.sol";
import "./FGelatoDebtBridge.sol";
import "./IInstaFeeCollector.sol";

contract ConditionMakerToAaveSafe is GelatoConditionsStandard {
    address public immutable instaFeeCollector;
    address public immutable oracleAggregator;

    constructor(address _instaFeeCollector, address _oracleAggregator) {
        instaFeeCollector = _instaFeeCollector;
        oracleAggregator = _oracleAggregator;
    }

    function getConditionData(
        address _dsa,
        uint256 _fromVaultId,
        address _colToken
    ) public pure virtual returns (bytes memory) {
        return
            abi.encodeWithSelector(
                this.aavePositionWillBeSafe.selector,
                _dsa,
                _fromVaultId,
                _colToken
            );
    }

    function ok(
        uint256,
        bytes calldata _conditionData,
        uint256
    ) public view virtual override returns (string memory) {
        (address _dsa, uint256 _fromVaultId, address _colToken) =
            abi.decode(_conditionData[4:], (address, uint256, address));

        return aavePositionWillBeSafe(_dsa, _fromVaultId, _colToken);
    }

    function aavePositionWillBeSafe(
        address _dsa,
        uint256 _fromVaultId,
        address _colToken
    ) public view returns (string memory) {
        return
            _aavePositionWillBeSafe(
                _dsa,
                _getMakerVaultCollateralBalance(_fromVaultId),
                _colToken,
                _getMaxAmtToBorrowMakerToAave(
                    _fromVaultId,
                    IInstaFeeCollector(instaFeeCollector).fee(),
                    oracleAggregator
                ),
                oracleAggregator
            )
                ? OK
                : "AavePositionWillNotBeSafe";
    }
}
