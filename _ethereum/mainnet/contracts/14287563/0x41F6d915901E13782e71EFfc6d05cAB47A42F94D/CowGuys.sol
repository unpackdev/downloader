// SPDX-License-Identifier: MIT

    /////////       ////////       ////                  ////        ///////////
  ///////       ////       ////     ////     /////      ////      //////
//////        /////        /////     ////   ///  ///   ////     //////    ////////
  //////       /////     /////        //// ///    /// ////        /////       ////
   /////////       ///////             //////      //////          /////////////


   // Creator's OpenSea Page: https://opensea.io/NFTBath
   // Twitter: @CowGuysNFT


pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract CowGuys is ERC721Enumerable, Ownable {
    using Strings for uint256;
    uint256 public maxSupply = 3333; // This will be the end of the story. :(
    string private baseURI = "";
    uint256 totalSupply_; // Check out how many Cow Guy NFTs has been minted until now.
    uint256 public balance;

    constructor() ERC721("Cow Guys", "COWG") {
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    receive() payable external {
        balance += msg.value;

    }
    // Let's mint!

    function mintNFT()
        public onlyOwner returns (uint256)
    {
        uint256 id = totalSupply();

        require( totalSupply() + 1 <= maxSupply, "Max NFT amount (3333) has been reached.");
        require( tx.origin == msg.sender, "You cannot mint on a custom contract!");

        _safeMint(msg.sender, id + 1); //starts from tokenID: 1 instead of 0.

        return id;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
    }

        function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
}

