pragma solidity ^0.7.3;

interface IQueue {

    function firstOrderId() external view returns (uint256);
    function nextOrderId() external view returns (uint256);
    function processedOrdersCount() external view returns (uint256);

    function queueOrder(bytes32 symbol, uint256 margin, uint256 positionId, address liquidator) external returns (uint256);

}