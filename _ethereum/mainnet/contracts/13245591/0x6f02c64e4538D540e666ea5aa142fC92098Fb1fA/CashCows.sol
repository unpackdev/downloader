// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

/**
 * @title Cash Cows contract
 * @dev Extends ERC721Enumerable Non-Fungible Token Standard basic implementation
 */
contract CashCows is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    string public PROVENANCE_HASH = "";

    uint256 public constant NFT_PRICE = 77700000000000000; //0.0777 ETH
    uint public constant MAX_NFT_PURCHASE = 5;
    uint256 public constant MAX_SUPPLY = 5000; // total including any presale

    uint256 public constant MAX_PRESALE_PURCHASE = 2;
    uint256 public constant MAX_PRESALE_SUPPLY = 500;


    bool public saleIsActive = false;
    bool public presaleIsActive = false;
    
    string private _baseURIExtended;

    constructor(string memory baseURI_) ERC721("Cash Cows", "CashCows") {
        _baseURIExtended = baseURI_;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Set provenance hash when revealed
    function setProvenanceHash(string memory _provenanceHash) external onlyOwner {
        PROVENANCE_HASH = _provenanceHash;
    }

    // Sets base URI for all tokens, only able to be called by contract owner
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    // Pause sale if active, make active if paused
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPresaleState() public onlyOwner {
        presaleIsActive = !presaleIsActive;
    }

    function mintCashCows(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Cash Cows");
        require(numberOfTokens <= MAX_NFT_PURCHASE, "Can only mint up to 5 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_SUPPLY, "Purchase would exceed max supply of Cash Cows");
        require(NFT_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function presaleMintCashCows(uint numberOfTokens) public payable {
        require(presaleIsActive, "Presale must be active to mint Cash Cows");
        require(numberOfTokens <= MAX_PRESALE_PURCHASE, "Can only mint 2 tokens at a time during presale");
        require(totalSupply().add(numberOfTokens) <= MAX_PRESALE_SUPPLY, "Purchase would exceed max presale supply of Cash Cows");
        require(NFT_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }
    
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory base = _baseURI();
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    //returns all token-ids owned by _owner
    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }
}