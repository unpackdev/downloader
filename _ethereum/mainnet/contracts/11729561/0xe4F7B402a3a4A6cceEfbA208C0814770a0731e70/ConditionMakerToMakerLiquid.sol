// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./GelatoConditionsStandard.sol";
import "./GelatoBytes.sol";
import "./FDebtCeilingIsReached.sol";
import "./FGelatoDebtBridge.sol";
import "./IInstaFeeCollector.sol";

contract ConditionMakerToMakerLiquid is GelatoConditionsStandard {
    using GelatoBytes for bytes;

    address public immutable instaFeeCollector;
    address public immutable oracleAggregator;

    constructor(address _instaFeeCollector, address _oracleAggregator) {
        instaFeeCollector = _instaFeeCollector;
        oracleAggregator = _oracleAggregator;
    }

    function getConditionData(
        address _dsa,
        uint256 _fromVaultId,
        uint256 _destVaultId,
        string calldata _destColType
    ) public pure virtual returns (bytes memory) {
        return
            abi.encodeWithSelector(
                this.isDebtCeilingReached.selector,
                _dsa,
                _fromVaultId,
                _destVaultId,
                _destColType
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
            uint256 _destVaultId,
            string memory _destColType
        ) = abi.decode(_conditionData[4:], (address, uint256, uint256, string));

        return
            isDebtCeilingReached(
                _dsa,
                _fromVaultId,
                _destVaultId,
                _destColType
            );
    }

    function isDebtCeilingReached(
        address _dsa,
        uint256 _fromVaultId,
        uint256 _destVaultId,
        string memory _destColType
    ) public view returns (string memory) {
        return
            _isDebtCeilingReached(
                _dsa,
                _destVaultId,
                _destColType,
                _getMaxAmtToBorrowMakerToMaker(
                    _fromVaultId,
                    _destVaultId == 0,
                    IInstaFeeCollector(instaFeeCollector).fee(),
                    oracleAggregator
                )
            )
                ? "MakerDebtCeilingReached"
                : OK;
    }
}
