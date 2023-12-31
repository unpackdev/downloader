// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract ProxyStorage {
    address internal _implementation;
}

contract ProxyAdmin is ProxyStorage {
    address private _admin;
    
    modifier onlyAdmin() {
        require(msg.sender == _admin, "Only admin can call this");
        _;
    }
    
    constructor() {
        _admin = msg.sender;
    }
    
    function upgradeTo(address newImplementation) external onlyAdmin {
        require(newImplementation != address(0), "New implementation is the zero address");
        require(newImplementation != _implementation, "New implementation is the same as the current one");
        _implementation = newImplementation;
    }
    
    function admin() external view returns (address) {
        return _admin;
    }
}

contract UpgradeableProxy is ProxyAdmin {    
    constructor(address initialImplementation) {
        _implementation = initialImplementation;
    }

    receive() external payable { }
    
    fallback() external payable {
        address impl = _implementation;
        require(impl != address(0), "Implementation not set");
        
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}