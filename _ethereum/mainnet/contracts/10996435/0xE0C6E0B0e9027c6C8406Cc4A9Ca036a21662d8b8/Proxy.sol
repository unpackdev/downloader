pragma solidity =0.4.26;

contract Proxy {
    address private constant constructorPlaceholder = 0xD21439d6742f79d858af3d87519587Ce930D8646;
    address private constant implementationPlaceholder = 0x7F2f24eE9Ec536635E60Ff905f1fC767fbf0575c;
    constructor(bytes data) public {
        bool success = constructorPlaceholder.delegatecall(data);
        if(!success) revert();
    }
    function() public payable {
        bool success = implementationPlaceholder.delegatecall(msg.data);
        assembly {
            let freememstart := mload(0x40)
            returndatacopy(freememstart, 0, returndatasize())
            switch success
            case 0 { revert(freememstart, returndatasize()) }
            default { return(freememstart, returndatasize()) }
        }
    }
}