// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./Ownable.sol";
import "./AccessControlEnumerable.sol";
import "./IContractAllowList.sol";

contract ContractAllowListProxy is Ownable,AccessControlEnumerable {
    // ==========================================================================
    // Section constants
    // ==========================================================================
    bytes32 public constant ADMIN = keccak256("ADMIN");

    // ==========================================================================
    // Section variables
    // ==========================================================================
    IContractAllowList public ICALcore;

    // ==========================================================================
    // Section modifier
    // ==========================================================================
    modifier onlyAdmin() {
        require(hasRole(ADMIN, msg.sender), "You are not admin.");
        _;
    }

    // ==========================================================================
    // Section external and public functions
    // ==========================================================================
    constructor(address _address) {
        _setRoleAdmin(ADMIN, ADMIN);
        _setupRole(ADMIN, msg.sender);

        ICALcore = IContractAllowList(_address);   
    } 

    function setICALcore(address _address) external onlyAdmin {
        ICALcore = IContractAllowList(_address);
    }

    function isAllowed(address _transferer,uint256 _level) external view returns(bool){
        return ICALcore.isAllowed(_transferer,_level);
    }
}
