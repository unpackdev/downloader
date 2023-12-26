// SPDX-License-Identifier: MIT
/** 
CROCS
*/

pragma solidity ^0.7.0;
pragma abicoder v2;

import "./ERC721.sol";
import "./Ownable.sol";

contract CrocsLeague is ERC721, Ownable {

    using Strings for uint256;
    
    string public CROC_PROVENANCE = ""; // IPFS PROVENANCE TO BE ADDED WHEN SOLD OUT

    string public LICENSE_TEXT = "";

    bool licenseLocked = false;

    uint256 public crocBasePrice = 70000000000000000; // 0.07 eth

    uint256 public constant crocsPerWallet = 7;

    uint256 public constant CROCS_SUPPLY = 4444;

    bool public availableForSale = false;

    event licenseisLocked(string _licenseText);

    constructor() public ERC721("Crocs League", "CROC") {}

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        CROC_PROVENANCE = provenanceHash;
    }

    function baseTokenURI() public view returns (string memory) {
      return "https://www.crocsleague.com/api/tokens/";
    }

    function flipSaleState() public onlyOwner {
        availableForSale = !availableForSale;
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    // Returns the license for tokens
    function tokenLicense(uint256 _id) public view returns (string memory) {
        require(_id < totalSupply(), "Please select a croc within the available supply");
        return LICENSE_TEXT;
    }

    // Locks the license to prevent further changes
    function lockLicense() public onlyOwner {
        licenseLocked = true;
        emit licenseisLocked(LICENSE_TEXT);
    }

    // Change the license
    function changeLicense(string memory _license) public onlyOwner {
        require(licenseLocked == false, "License is locked");
        LICENSE_TEXT = _license;
    }

    function setCrocBasePrice(uint256 price) public onlyOwner {
        crocBasePrice = price;
    }

    function mintCroc(uint256 numberOfTokens) public payable {
        require(availableForSale, "Minting can only occur when the sale is active");
        require(numberOfTokens > 0, "Must mint at least 1 croc");
        require(numberOfTokens <= crocsPerWallet, "Each wallet can only mint up to 7 crocs");
        require(
            numberOfTokens <= CROCS_SUPPLY - totalSupply(),
            "Not enough crocs left to mint"
        );
        require(
            msg.value >= crocBasePrice * numberOfTokens,
            "Incorrect ETH sent"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < CROCS_SUPPLY) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId));
        return string(abi.encodePacked(
            baseTokenURI(),
            _tokenId.toString()
        ));
    }
  
}