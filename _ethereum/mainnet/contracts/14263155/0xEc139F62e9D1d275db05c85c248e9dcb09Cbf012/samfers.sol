// SPDX-License-Identifier: MIT

/*
 #####     #    #     # ####### ####### ######   #####  
#     #   # #   ##   ## #       #       #     # #     # 
#        #   #  # # # # #       #       #     # #       
 #####  #     # #  #  # #####   #####   ######   #####  
      # ####### #     # #       #       #   #         # 
#     # #     # #     # #       #       #    #  #     # 
 #####  #     # #     # #       ####### #     #  #####                                  
*/


pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract samfers is ERC721, ERC721Enumerable, Ownable {
    string private _baseURIextended = "ipfs://QmWiQE65tmpYzcokCheQmng2DCM33DEhjXcPB6PanwpAZo/";
    address payable public immutable bro;
    address payable public immutable unicef;//0xA59B29d7dbC9794d1e7f45123C48b2b8d0a34636 is the UNICEFFrance address --> https://lp.unicef.fr/donate-in-cryptocurrencies-addresses/
    address payable public immutable sartoshi;//0x9b2a5804d0b835851c78dfeabdccd517568dd9a2;
    bool public mintPhase = false;

    constructor(address payable bro_, address payable unicef_, address payable sartoshi_) ERC721("samfers", "SAMFER") {
        bro = bro_;
        unicef = unicef_;
        sartoshi = sartoshi_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }
    function setMint() external onlyOwner() {
        mintPhase = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function reserve(uint nb) public onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < nb; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function freeMint(uint numberOfTokens) public {
        require(mintPhase, "Not yet minting phase");
        require(numberOfTokens <= 3, "Exceeded max token freemint)");
        require(totalSupply() + numberOfTokens <= 2000, "Freemint is only for the 2000 firsts");
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < 2000) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function mint(uint numberOfTokens) public payable {
        require(mintPhase, "Not yet minting phase");
        require(totalSupply() + numberOfTokens <= 10021, "Exceed max supply of tokens");
        require(0.01 ether * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < 10021) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function withdraw() public onlyOwner {
        uint giftValue = address(this).balance / 10;
        uint broValue = address(this).balance / 10 * 4 ;
        payable(unicef).transfer(giftValue);
        payable(msg.sender).transfer(broValue);
        payable(bro).transfer(broValue);
        payable(sartoshi).transfer(giftValue);
    }
}