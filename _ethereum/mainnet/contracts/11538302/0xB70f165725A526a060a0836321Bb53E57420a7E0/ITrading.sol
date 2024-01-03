pragma solidity ^0.7.3;

interface ITrading {

    function processOrder(uint256 id, bytes32 symbol, uint256 price, uint256 margin, uint256 positionId, address liquidator) external;
    function cancelOrder(uint256 id, uint256 positionId, address liquidator, string calldata reason) external;

}