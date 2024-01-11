//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";


contract HeHe is ERC721A, Ownable, ReentrancyGuard {
    


  
    
    

    constructor()
        ERC721A("Collection Name", "SYMBL")

    {
     
      
    }




    function airdrop(address[] calldata addresses) public onlyOwner{
        for(uint i; i<addresses.length;i++){
            _safeMint(addresses[i],1);
        }
    }
    

}