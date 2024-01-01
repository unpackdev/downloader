// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StorageSlot {
    struct AddressSlot {
        address value;
    }
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

contract Proxy {
    //EIP1967 Impl_solt: keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    //EIP1967 Admin_solt: keccak-256 hash of "eip1967.proxy.admin" subtracted by 1
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    event Upgraded(address indexed impl);
    event AdminChanged(address preAdmin, address newAdmin);

    modifier onlyAmdin(){
        require(msg.sender == admin(), "Porxy: Caller not admin");
        _;
    }

    function _setAdmin(address _admin) internal {
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = _admin;
    }

    function _setLogic(address _logic) internal {
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = _logic;
    }

    function logic() public view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function admin() public view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    function changeAdmin(address newAdmin) external onlyAmdin returns(bool) {
        address oldAdmin = admin();
        _setAdmin(newAdmin);
        emit AdminChanged(oldAdmin, newAdmin);
        return true;
    }

    function upgrad(address newLogic) external onlyAmdin returns(bool) {
        _setLogic(newLogic);
        emit Upgraded(newLogic);
        return true;
    }


    fallback () external payable {
        assembly {
            let impl := sload(_IMPLEMENTATION_SLOT)
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive () external payable virtual {}
}


contract FactoryProxyV2 is Proxy{
    constructor(address factory){
        _setLogic(factory);
        _setAdmin(msg.sender);
    }
}