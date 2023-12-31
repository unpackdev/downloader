// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct SwapDetail {
    uint amountIn;
    address[] path;
    address adapter;
}

interface IDABotFarmingModuleEvent {
    event WorkerAdded(address indexed worker);
    event WorkerRemoved(address indexed worker);
    event OperatorUpdated(address indexed account, bool status);
    event Swap(address indexed from, address indexed to, uint amountIn, uint amountOut, address adapter);
    event Repay(address indexed worker, address platformToken, uint amount);
}

interface IDABotFarmingModule is IDABotFarmingModuleEvent {

    function allWorkers() external view returns(address[] memory workers);

    function deployWorker(
        address engineTemplate,
        uint16[] calldata pIDs,
        bytes[] calldata values
    ) external returns(address worker);

    function canRemoveWorker(address worker) external view returns(bool);

    function indexOfWorker(address worker) external view returns(bool found, uint index);

    function removeWorker(uint index) external;

    function setOperator(address account, bool status) external; 

    function isOperator(address account) external view returns(bool);

    function swap(SwapDetail[] calldata details) external;

    function repay(uint index, address platformToken, uint amount) external;
}
