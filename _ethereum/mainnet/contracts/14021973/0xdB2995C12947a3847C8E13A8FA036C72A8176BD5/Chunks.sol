// SPDX-License-Identifier: BSD-3-Clause

/************************************************************************************************************

     □□□□□□□□□□     □□□□□      □□□□□  □□□□□      □□□□□  □□□□□      □□□□□  □□□□□     □□□□□  □□□□□       □□□□□
    □□□□□□□□□□□□    □□□□□      □□□□□  □□□□□      □□□□□  □□□□□□     □□□□□  □□□□□    □□□□□    □□□□□     □□□□□
  □□□□□      □□□□□  □□□□□      □□□□□  □□□□□      □□□□□  □□□□□□□    □□□□□  □□□□□   □□□□□      □□□□□   □□□□□   
  □□□□□      □□□□□  □□□□□      □□□□□  □□□□□      □□□□□  □□□□□□□□   □□□□□  □□□□□  □□□□□        □□□□□ □□□□□  
  □□□□□             □□□□□      □□□□□  □□□□□      □□□□□  □□□□□□□□□  □□□□□  □□□□□ □□□□□          □□□□□□□□□ 
  □□□□□             □□□□□□□□□□□□□□□□  □□□□□      □□□□□  □□□□□ □□□□ □□□□□  □□□□□□□□□□            □□□□□□□
  □□□□□             □□□□□□□□□□□□□□□□  □□□□□      □□□□□  □□□□□  □□□□□□□□□  □□□□□□□□□□             □□□□□
  □□□□□             □□□□□      □□□□□  □□□□□      □□□□□  □□□□□   □□□□□□□□  □□□□□ □□□□□            □□□□□   
  □□□□□      □□□□□  □□□□□      □□□□□  □□□□□      □□□□□  □□□□□    □□□□□□□  □□□□□  □□□□□           □□□□□   
  □□□□□      □□□□□  □□□□□      □□□□□  □□□□□      □□□□□  □□□□□     □□□□□□  □□□□□   □□□□□          □□□□□
    □□□□□□□□□□□□    □□□□□      □□□□□    □□□□□□□□□□□□    □□□□□      □□□□□  □□□□□    □□□□□         □□□□□  
     □□□□□□□□□□     □□□□□      □□□□□     □□□□□□□□□□     □□□□□      □□□□□  □□□□□     □□□□□        □□□□□

         □□□□□□□□□□□□□     □□□□□      □□□□□  □□□□□      □□□□□  □□□□□     □□□□□      □□□□□□□□□□     
         □□□□□□□□□□□□□□    □□□□□      □□□□□  □□□□□□     □□□□□  □□□□□    □□□□□      □□□□□□□□□□□□      
         □□□□□      □□□□□  □□□□□      □□□□□  □□□□□□□    □□□□□  □□□□□   □□□□□     □□□□□      □□□□□
         □□□□□      □□□□□  □□□□□      □□□□□  □□□□□□□□   □□□□□  □□□□□  □□□□□      □□□□□      □□□□□    
         □□□□□      □□□□□  □□□□□      □□□□□  □□□□□□□□□  □□□□□  □□□□□ □□□□□         □□□□□           
         □□□□□□□□□□□□□□    □□□□□      □□□□□  □□□□□ □□□□ □□□□□  □□□□□□□□□□            □□□□□             
         □□□□□□□□□□□□□     □□□□□      □□□□□  □□□□□  □□□□□□□□□  □□□□□□□□□□               □□□□□      
         □□□□□             □□□□□      □□□□□  □□□□□   □□□□□□□□  □□□□□ □□□□□               □□□□□  
         □□□□□             □□□□□      □□□□□  □□□□□    □□□□□□□  □□□□□  □□□□□      □□□□□      □□□□□
         □□□□□             □□□□□      □□□□□  □□□□□     □□□□□□  □□□□□   □□□□□     □□□□□      □□□□□
         □□□□□               □□□□□□□□□□□□    □□□□□      □□□□□  □□□□□    □□□□□      □□□□□□□□□□□□
         □□□□□                □□□□□□□□□□     □□□□□      □□□□□  □□□□□     □□□□□      □□□□□□□□□□

                          Live life, stay fat.

************************************************************************************************************/



pragma solidity ^0.8.0;

import "./ERC721EnumerableB.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract ChunkyPunksNFT is ERC721EnumerableB, Ownable {
    using Strings for uint256;

    string public PROVENANCE = "";
    uint256 public maxSupply = 6900;
    
    uint256 public price = 0.0169 ether; //WEI: 16900000000000000

    //sale active
    bool public paused = true;

    //add after deploy
    string private _baseTokenURI = "";
    string private _tokenURISuffix = "";

    constructor() ERC721B("Chunky Punks NFT", "CHPUNKS") {}

    //external
    fallback() external payable {}
    receive() external payable {}

    function mint(uint256 quantity) external payable {
        uint256 balance = totalSupply();
        require(!paused, "Sale is locked");
        require(balance + quantity <= maxSupply, "Exceeds supply");
        require(msg.value >= price * quantity, "Ether sent is not correct");

        for (uint256 i; i < quantity; ++i) {
            _safeMint(msg.sender, balance + i);
        }
    }

    function gift(uint256 quantity, address recipient) external onlyOwner {
        uint256 balance = totalSupply();
        require(balance + quantity <= maxSupply, "Exceeds supply");

        for (uint256 i; i < quantity; ++i) {
            _safeMint(recipient, balance + i);
        }
    }

    function setLocked(bool paused_) external onlyOwner {
        paused = paused_;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setProvenance(string memory provenanceHash) external onlyOwner {
        PROVENANCE = provenanceHash;
    }

    function withdraw() external onlyOwner {
        require(address(this).balance >= 0, "No funds available");
        Address.sendValue(payable(owner()), address(this).balance);
    }

    function setBaseURI(string memory baseURI, string memory suffix)
        external
        onlyOwner
    {
        _baseTokenURI = baseURI;
        _tokenURISuffix = suffix;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: TOKEN DOES NOT EXIST"
        );
        return
            string(
                abi.encodePacked(
                    _baseTokenURI,
                    tokenId.toString(),
                    _tokenURISuffix
                )
            );
    }
}