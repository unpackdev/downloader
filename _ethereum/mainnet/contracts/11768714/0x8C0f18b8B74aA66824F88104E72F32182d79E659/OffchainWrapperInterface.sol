pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./DFSExchangeData.sol";

abstract contract OffchainWrapperInterface is DFSExchangeData {
    function takeOrder(
        ExchangeData memory _exData,
        ActionType _type
    ) virtual public payable returns (bool success, uint256);
}
