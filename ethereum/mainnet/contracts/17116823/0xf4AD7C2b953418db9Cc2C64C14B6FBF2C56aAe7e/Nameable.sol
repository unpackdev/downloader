// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./IERC721Metadata.sol";
import "./SetNameable.sol";

abstract contract Nameable is IERC721Metadata {   
    using SetNameable for NameableData;      
    NameableData nameable;

    constructor(string memory _name, string memory _symbol) {
        nameable.setNamed(_name, _symbol);
    }

    function name() public virtual override view returns (string memory) {
        return nameable.getName();
    }  

    function symbol() public virtual override view returns (string memory) {
        return nameable.getSymbol();
    }          
      
}