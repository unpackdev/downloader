// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

//DEV by @0x22061

contract LuckyTagsArmadaGenesisCollection is ERC721, Ownable {
    string public PROVENANCE;
    bool public saleIsActive = false;
    string private _baseURIextended;
    uint public currentIndex = 0;

    constructor(string memory baseURI) ERC721("Lucky Tags Armada Genesis Collection", "LTAGC") {
        _baseURIextended = baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }
    
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    //get Total Supply
    function totalSupply() view public returns (uint){
        return currentIndex;
    }

    function mint() public {
        require(saleIsActive, "Sale must be active to mint");
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(currentIndex + 1 <= 501, "Purchase would exceed max supply of");
 
        _safeMint(msg.sender, currentIndex + 1);
        currentIndex += 1;
    }
}
