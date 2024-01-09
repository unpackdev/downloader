// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Borp.sol";
import "./Strings.sol";

contract BorpaDAO is Ownable, ERC721Borp, ReentrancyGuard {
    uint256 public immutable amountForSale;
    uint256 public immutable maxPerAddressDuringMint;
    uint256 public constant amountForFree = 751;
    uint256 public constant priceAfterFree = .025 ether;
    bool public isMintActive = false;
    
    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_
    ) ERC721Borp("BorpaDAO Chad Pass", "BORPA", maxBatchSize_, collectionSize_  ) {
        amountForSale = collectionSize_;
        maxPerAddressDuringMint = 15;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

        
    function flipMintState() public onlyOwner {
        isMintActive = !isMintActive;
    }

    function FreeMint(uint256 quantity) external payable callerIsUser {
        require(isMintActive, "Sale must be active to mint");
        require(
            numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
            "can not mint more during this phase"
        );
        require(
         quantity <= maxBatchSize,
            "can not mint this many in one go"
        );
        require(
            totalSupply() + quantity <= collectionSize,
            "reached max supply"
        );
        require(
            quantity <= remainingFree(), 
            "Your quantity exceeds the number of free remaining"
        );
        _safeMint(msg.sender, quantity);
    }

        function Mint(uint256 quantity) external payable callerIsUser {
        require(isMintActive, "Sale must be active to mint");
        require(msg.value >= (currentPrice() * quantity), "Minting Price is not enough");
        require(
            totalSupply() + quantity <= collectionSize,
            "reached max supply"
        );
        require(
             quantity <= maxBatchSize,
            "can not mint this many in one go"
        );
        require(
            remainingFree() == 0,
            "Free Mints still remain. Mint them before they are gone!!"
        );
        require(
         numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
            "can not mint this many"
        );
        _safeMint(msg.sender, quantity);
    }

    function currentPrice() public view returns (uint256) {
        if(totalSupply() < amountForFree){
            return 0;
        } 
        else {
            return priceAfterFree;
        }      
    }

    function remainingFree() public view returns (uint256) {
        if(totalSupply() > amountForFree){
            return 0;
        } else {
            return amountForFree - totalSupply() ;
        }
 
    }

    string private _baseTokenURI;

   function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
}