// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./GelatoConditionsStandard.sol";
import "./GelatoBytes.sol";
import "./FAaveHasLiquidity.sol";
import "./CTokens.sol";
import "./FGelatoDebtBridge.sol";
import "./IInstaFeeCollector.sol";

contract ConditionMakerToAaveLiquid is GelatoConditionsStandard {
    using GelatoBytes for bytes;

    address public immutable instaFeeCollector;
    address public immutable oracleAggregator;

    constructor(address _instaFeeCollector, address _oracleAggregator) {
        instaFeeCollector = _instaFeeCollector;
        oracleAggregator = _oracleAggregator;
    }

    function getConditionData(uint256 _fromVaultId)
        public
        pure
        virtual
        returns (bytes memory)
    {
        return abi.encodeWithSelector(this.hasLiquidity.selector, _fromVaultId);
    }

    function ok(
        uint256,
        bytes calldata _conditionData,
        uint256
    ) public view virtual override returns (string memory) {
        uint256 _fromVaultId = abi.decode(_conditionData[4:], (uint256));

        return hasLiquidity(_fromVaultId);
    }

    function hasLiquidity(uint256 _fromVaultId)
        public
        view
        returns (string memory)
    {
        return
            _isAaveLiquid(
                DAI,
                _getMaxAmtToBorrowMakerToAave(
                    _fromVaultId,
                    IInstaFeeCollector(instaFeeCollector).fee(),
                    oracleAggregator
                )
            )
                ? OK
                : "AaveIlliquid";
    }
}
