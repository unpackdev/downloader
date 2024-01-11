// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";



contract iwwon11 is Ownable,ERC721Enumerable {





    // Base URI
    string private baseURIextended;

    /* ************************************************************
    *       CONSTRUCTOR
    **************************************************************/
    constructor() ERC721("iwwon 1/1", "IWW11") {
    }




    function mintToken(uint numberOfTokens) public onlyOwner {

        
        for(uint i = 0; i < numberOfTokens; i++) {
            
            uint mintIndex = totalSupply()+1;     
            _safeMint(msg.sender, mintIndex);
            
        }
    }
   
    function mintTokenTo(address  _to,uint numberOfTokens) public onlyOwner {

        
        for(uint i = 0; i < numberOfTokens; i++) {
            
            uint mintIndex = totalSupply()+1;     
            _safeMint(_to, mintIndex);
            
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURIextended;
    }

    function baseURI() public view returns (string memory) {
        return baseURIextended;
    }

    function setBaseURI(string memory abaseURI) public onlyOwner {
        baseURIextended=abaseURI;
    }

    
}