// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.23;

contract factory {
    address _owner;
    address private _codeAddress;

    constructor() {
        _owner = msg.sender;
    }

    function changeOwner(address owner) external {
        require(msg.sender == _owner);
        _owner = owner;
    }

    function deploy(uint salt, bytes memory runtimeCode) external returns(address rtnAddress) {
        require(msg.sender == _owner);

        address addr;
        assembly {
            addr := create(0, add(runtimeCode, 0x20), mload(runtimeCode))
        }
        _codeAddress = addr;

        bytes memory bytecode = hex"5860208158601c335a6338cc48318752fa158151803b80938091923cf3";
        assembly {
            rtnAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
    }

    function deploy(uint salt, address codeAddress) external returns(address rtnAddress) {
        require(msg.sender == _owner);

        _codeAddress = codeAddress;

        bytes memory bytecode = hex"5860208158601c335a6338cc48318752fa158151803b80938091923cf3";
        assembly {
            rtnAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
    }

    function getAddress() external view returns(address) {
        return _codeAddress;
    }
}