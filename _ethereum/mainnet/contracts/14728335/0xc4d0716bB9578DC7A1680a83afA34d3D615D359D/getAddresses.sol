pragma solidity ^0.8.10;
//SPDX-License-Identifier: MIT

import "./ERC721.sol";

contract NFTProject is ERC721 {
    constructor() ERC721("contractname", "CONTRACT") 
    {
    }
}


contract getAddresses {

    function getAddr(address addr, uint256 numTokens) public view returns (address[] memory) {
        address[] memory owners = new address[](numTokens);

        NFTProject project = NFTProject(addr);

        if (numTokens > 0){
            for (uint256 i = 0; i < numTokens; i++) {
                owners[i] = project.ownerOf(i+1);
            }
        }

        return owners;
    }

}