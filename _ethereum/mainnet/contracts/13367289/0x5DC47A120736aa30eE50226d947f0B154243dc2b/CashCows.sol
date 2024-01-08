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
    uint public constant MAX_NFT_PURCHASE = 20; // per tx
    uint256 public MAX_SUPPLY = 5000; // total including any presale

    uint public constant MAX_PRESALE_PURCHASE = 5; // per person
    uint256 public constant MAX_PRESALE_SUPPLY = 500;

    uint256 public constant RESERVED_COWS = 20;
    uint256 public reservedClaimed = 0;

    mapping(address => bool) private _presaleEligible;
    mapping(address => uint256) private _totalClaimed;


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

    function claimReserved(address recipient, uint numberOfTokens) external onlyOwner {
        require(reservedClaimed < RESERVED_COWS, "Already have claimed all reserved cows");
        require(reservedClaimed.add(numberOfTokens) <= RESERVED_COWS, "Minting would exceed max reserved cows");
        require(recipient != address(0), "Cannot add null address");
        require(totalSupply() < MAX_SUPPLY, "All tokens have been minted");
        require(totalSupply() + reservedClaimed <= MAX_SUPPLY, "Minting would exceed max supply");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(recipient, mintIndex);
            }
        }
        reservedClaimed += numberOfTokens;
    }

    function mintCashCows(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Cash Cows");
        require(numberOfTokens <= MAX_NFT_PURCHASE, "Can only mint up to 20 tokens at a time");
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
        require(_presaleEligible[msg.sender], "You are not eligible for the presale");
        require(totalSupply() < MAX_PRESALE_SUPPLY, "All presale tokens have been minted");
        require(_totalClaimed[msg.sender].add(numberOfTokens) <= MAX_PRESALE_PURCHASE, "Purchase exceeds max allowed");
        require(numberOfTokens > 0, "Must mint at least one cow");
        require(numberOfTokens <= MAX_PRESALE_PURCHASE, "Can only mint up to 5 tokens at a time during presale");
        require(totalSupply().add(numberOfTokens) <= MAX_PRESALE_SUPPLY, "Purchase would exceed max presale supply of Cash Cows");
        require(NFT_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_SUPPLY) {
                _totalClaimed[msg.sender] += 1;
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function addToPresale(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Cannot add null address");

            _presaleEligible[addresses[i]] = true;
            _totalClaimed[addresses[i]] > 0 ? _totalClaimed[addresses[i]] : 0;
        }
    }

    /* decrease max supply */
    function decreaseMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply < MAX_SUPPLY, "can only decrease max supply");
        require(totalSupply() <= newMaxSupply, "cannot decrease below total minted");
        MAX_SUPPLY = newMaxSupply;
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