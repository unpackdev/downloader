contract MyContractProxy {
    address public targetContract;

    constructor(address _targetContract) {
        targetContract = _targetContract;
    }

    function upgrade(address _newTargetContract) public {
        targetContract = _newTargetContract;
    }

    fallback() external payable {
        // Forward all calls to the target contract
        address _impl = targetContract;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 { revert(0, returndatasize()) }
                default { return(0, returndatasize()) }
        }
    }
}