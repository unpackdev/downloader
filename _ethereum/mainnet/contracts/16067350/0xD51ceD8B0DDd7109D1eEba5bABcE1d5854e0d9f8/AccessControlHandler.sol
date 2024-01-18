// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "./IAccessControlUpgradeable.sol";
import "./Ownable.sol";
// import "./console.sol";

interface IAccessControl {
    function grantRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}


contract AccessControlHandler is Ownable {

    address[] public contractsAccessControl;

    constructor(address[] memory _contractsAccessControl) {
        addAccessControlAddressBath(_contractsAccessControl);
    }

    function addAccessControlAddressBath(address[] memory _accessContracts) public onlyOwner {
        for(uint256 contractItem = 0; contractItem < _accessContracts.length; contractItem++) {
            contractsAccessControl.push(_accessContracts[contractItem]);
        }
    }


    function removeAccessControlAddressBath(address accessContract) external onlyOwner {
        for(uint256 index = 0; index < contractsAccessControl.length; index++) {
            if (contractsAccessControl[index] == accessContract) {
                for(uint i = index; i < contractsAccessControl.length-1; i++){
                    contractsAccessControl[i] = contractsAccessControl[i+1];
                }
                contractsAccessControl.pop();
            }
        }
    }

    // @dev Grant role for meny contracts
    function grantRole(bytes32 role, address account) public onlyOwner {
        IAccessControl accessControl;

        for(uint256 contractItem = 0; contractItem < contractsAccessControl.length; contractItem++) {
            accessControl = IAccessControl(contractsAccessControl[contractItem]);
            accessControl.grantRole(role, account);
        }
    }

    // @dev Renounce role for meny contracts
    function renounceRole(bytes32 role, address account) public onlyOwner {
        IAccessControl accessControl;

        for(uint256 contractItem = 0; contractItem < contractsAccessControl.length; contractItem++) {
            accessControl = IAccessControl(contractsAccessControl[contractItem]);
            accessControl.renounceRole(role, account);
        }
    }

    // @dev Bath Grant role for meny contracts
    function grantRoleBath(bytes32[] calldata roles, address[] memory accounts) external onlyOwner {
        require(roles.length == accounts.length, "ACH: Wrong data");

        for(uint256 i = 0; i < accounts.length; i++) {
            grantRole(roles[i], accounts[i]);
        }
    }

    // @dev Bath renounce role for meny contracts
    function renounceRoleBath(bytes32[] calldata roles, address[] memory accounts) external onlyOwner {
        require(roles.length == accounts.length, "ACH: Wrong data");

        for(uint256 i = 0; i < accounts.length; i++) {
            renounceRole(roles[i], accounts[i]);
        }
    }
}
