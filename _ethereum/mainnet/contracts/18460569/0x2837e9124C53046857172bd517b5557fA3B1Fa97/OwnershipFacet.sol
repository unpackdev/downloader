// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


import "./LibDiamond.sol";
import "./IERC173.sol";

contract OwnershipFacet is IERC173 {
    function transferOwnership(address newOwner) external override {
        LibDiamond.setContractOwner(newOwner);
    }
    function owner() external override view returns (address) {
        return LibDiamond.contractOwner();
    }
    
    function setDBControlWhitelist(address[] memory _modules,bool[] memory _status)  external {
        LibDiamond.setDBControlWhitelist(_modules,_status);
    }
    function getDBControlWhitelist(address _module) external view returns(bool){
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();  
        return ds.dBControlWhitelist[_module];
    }
}
