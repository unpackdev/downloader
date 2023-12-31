pragma solidity 0.8.17;

interface IOrallyPythiaExecutorsRegistry {
    function isExecutor(address _addr) external view returns (bool);
}

contract OrallyPythiaConsumer {
    IOrallyPythiaExecutorsRegistry public registry;

    constructor(address _registry) {
        registry = IOrallyPythiaExecutorsRegistry(_registry);
    }

    function isExecutor(address _addr) public view returns (bool) {
        return registry.isExecutor(_addr);
    }

    modifier onlyExecutor() {
        require(
            registry.isExecutor(msg.sender),
            "OrallyPythiaConsumer: Caller is not an executor"
        );
        _;
    }
}

contract OrallyMulticall is OrallyPythiaConsumer {
    constructor(address _pythiaRegistry) OrallyPythiaConsumer(_pythiaRegistry) {}

    struct Call {
        address target;
        bytes callData;
        uint256 gasLimit;
    }

    struct Transfer {
        address target;
        uint256 value;
    }

    struct Result {
        bool success;
        uint256 usedGas;
        bytes returnData;
    }

    function multicall(Call[] calldata calls) public onlyExecutor returns (Result[] memory) {
        uint256 length = calls.length;
        Result[] memory returnData = new Result[](length);
        uint256 gasBefore;
        for (uint256 i = 0; i < length; i++) {
            gasBefore = gasleft();
            if (gasBefore < (calls[i].gasLimit + 1000) && length != 1) {
                return returnData;
            }

            Result memory result = returnData[i];
            (result.success, result.returnData) = calls[i].target.call(
                calls[i].callData
            );
            result.usedGas = gasBefore - gasleft();
            returnData[i] = result;
        }

        return returnData;
    }

    function multitransfer(Transfer[] calldata transfers) public payable onlyExecutor {
        for (uint256 i = 0; i < transfers.length; i++) {
            payable(transfers[i].target).transfer(transfers[i].value);
        }
    }
}