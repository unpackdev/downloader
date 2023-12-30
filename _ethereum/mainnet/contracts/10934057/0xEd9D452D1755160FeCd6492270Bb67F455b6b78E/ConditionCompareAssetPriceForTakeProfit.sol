pragma solidity ^0.6.2;

import "./GelatoConditionsStandard.sol";
import "./SafeMath.sol";
import "./GelatoBytes.sol";

contract ConditionCompareAssetPriceForTakeProfit is GelatoConditionsStandard {

    using GelatoBytes for bytes;

    function getConditionData( address _source, bytes calldata  _sourceData, int _limit)
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
         int limit) = abi.decode(
            _conditionData,
            (address,bytes,int)
        );

        return takeProfit(source, sourceData, limit);
    }

    function takeProfit(address _source, bytes memory _sourceData, int limit)
        internal
        view
        returns(string memory)
    {
        (bool success, bytes memory returndata) = _source.staticcall(_sourceData);
        if(!success) {
            return returndata.generateErrorString(
                "ConditionCompareAssetPrice.takeProfit._source:"
            );
        }

        int price = abi.decode(returndata, (int));

        if (price >= limit) return OK;
        return "NotOKPriceStillLesserThanTheTakeProfitLimit";
    }
}