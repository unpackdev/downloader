// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WLHubFront {
    address public __implementation;
    address __owner;

    constructor() {
        __owner = msg.sender;
    }

    function __upgrade(address _newImplementation) public {
        require(msg.sender == __owner, "WLHubFront: Not authorized");
        __implementation = _newImplementation;
    }

    fallback() external payable {
        address _impl = __implementation;
        require(_impl != address(0), "Implementation contract not set");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}