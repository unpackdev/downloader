pragma solidity ^0.6.2;

import "./GelatoConditionsStandard.sol";
import "./SafeMath.sol";
import "./GelatoBytes.sol";

contract ConditionCompareAssetPriceForStopLoss is GelatoConditionsStandard {

    using GelatoBytes for bytes;

    function getConditionData( address _source, bytes calldata  _sourceData, uint _limit)
        public
        pure
        virtual
        returns (bytes memory)
    {
        return abi.encode(_source, _sourceData, _limit);
    }
    function ok(uint256, bytes calldata _conditionData, uint256)
        public
        view
        virtual
        override
        returns (string memory)
    {
        (address source,
         bytes memory sourceData,
         uint limit) = abi.decode(
            _conditionData,
            (address,bytes,uint)
        );

        return stopLoss(source, sourceData, limit);
    }

    function stopLoss(address _source, bytes memory _sourceData, uint limit)
        internal
        view
        returns(string memory)
    {
        (bool success, bytes memory returndata) = _source.staticcall(_sourceData);
        if(!success) {
            return returndata.generateErrorString(
                "ConditionCompareAssetPrice.stopLoss._source:"
            );
        }

        uint price = abi.decode(returndata, (uint));

        if (price <= limit) return OK;
        return "NotOKPriceStillGreaterThanTheStopLossLimit";
    }
}