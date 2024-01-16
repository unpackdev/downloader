
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;


import "./Context.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

contract JustFreeMint is ERC721A, Ownable {

    string baseURI;
    
    uint public price = 0.001 ether;
    uint public maxFreeMintPerWallet = 1;
    uint public MAX_SUPPLY = 999;
    bool public active = false;
    
    mapping(address => uint) public addressToFreeMinted;

    constructor() ERC721A("Just FREE", "JFREE") {
    }

    
    function freeMint() external  {

        require(addressToFreeMinted[msg.sender] < maxFreeMintPerWallet, "You already minted for free");
        require(totalSupply()<MAX_SUPPLY, "SOLD OUT");    
        _safeMint(msg.sender, 1);
        
       
    }
    
       function setBaseURI(string calldata ipfsLink) external onlyOwner {
        baseURI = ipfsLink;
    }

       function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
        function ActiveContract() public onlyOwner {
        active = !active;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        //string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId),".json")) : '';
    }


        function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

}