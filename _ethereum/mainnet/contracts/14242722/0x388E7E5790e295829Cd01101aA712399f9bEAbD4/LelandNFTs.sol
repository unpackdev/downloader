// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";


contract LelandNFTs is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public Supply = 10000000;
    bool public SupplyLocked;
    bool public metadataFrozen;
    string public BaseURI;
    bool public SalePaused;
    uint256 public MintCost;
    string private exclusiveURI;
    mapping(uint256 => bool) private exclusiveTokens;



    constructor (string memory bURI, string memory exclusiveLink, uint256 mintCost) 
    ERC721A("Everybody Loves Me", "ELM", 1200, 10000000){
        BaseURI = bURI;
        exclusiveURI = exclusiveLink;
        MintCost = mintCost;
        SalePaused = true;
    }

    /*
    Below are functions accesseble to the owner of the contract.
    These are admin functions to alter state.
    */

    function pause() public onlyOwner {
        SalePaused = !SalePaused;
    }

    function setBaseURI(string memory bURI) public onlyOwner {
        require(!metadataFrozen, "Metadata has been locked and permenantly decentralized");
        BaseURI = bURI;
    }

    function setExclusiveURI(string memory exclusiveLink) public onlyOwner {
        require(!metadataFrozen, "Metadata has been locked and permenantly decentralized");
        exclusiveURI = exclusiveLink;
    }

    function freezeMetadata() public onlyOwner {
        metadataFrozen = true;
        //Once function called, metadata can no longer be altered
    }

    function adjustSupply(uint256 newSupply) public onlyOwner {
        require(!SupplyLocked, "Supply is permenatly locked");
        Supply = newSupply;
    }

    function lockSupply() public onlyOwner {
        SupplyLocked = true;
        //Once function called, Supply can no longer be altered
    }

    function changePrice(uint256 newWeiPrice) public onlyOwner {
        MintCost = newWeiPrice;
    }

     function withdraw(uint256 amountinwei, bool getall) public onlyOwner nonReentrant {
        if(getall == true){
            (bool success, ) = msg.sender.call{value: address(this).balance}("");
            require(success, "Balance transfered unsuccessfully");
        } else {
            require(amountinwei<address(this).balance,"Contract is not worth that much yet");
             (bool success, ) = msg.sender.call{value: amountinwei}("");
             require(success, "Balance transfered unsuccessfully");
        }
    }

    function reserve(uint256 quantity, address recipient) public onlyOwner {
        require(totalSupply() + quantity <= Supply, "Quantity exceeds supply");
        require(quantity <= maxBatchSize, "Only mint up to batchsize");
        _safeMint(recipient, quantity);
    }

    function airDropSingleBatches(address[] memory recipients) public onlyOwner {
        require(totalSupply() + recipients.length*12 <= Supply, "Quantity exceeds supply");
        for (uint256 i = 0; i < recipients.length; i++){
            _safeMint(recipients[i], 12);   
        }
    }

    function airDrop(address[] memory recipients, uint256[] memory numberOfSets) public onlyOwner {
        require(totalSupply() + recipients.length*12 <= Supply, "Quantity exceeds supply");
        for (uint256 i = 0; i < recipients.length; i++){
            require(12*numberOfSets[i] <= maxBatchSize, "Only mint up to batchsize");
            _safeMint(recipients[i], 12*numberOfSets[i]);   
        }
    }

    function mintExclusive(address recipient) public onlyOwner {
        require(totalSupply() + 1 <= Supply, "Quantity exceeds supply");
        uint256 tokenID = totalSupply();
        exclusiveTokens[tokenID] = true;
        _safeMint(recipient, 1);
    }

    /*
    Below are public payable functions that alter contract state.
    */

    function mintNFT() external payable {
        require(!SalePaused, "Sale not active");
        require(msg.value >= MintCost, "Incorrect value sent");
        require(totalSupply() + 12 <= Supply, "Quantity exceeds supply");   
        _safeMint(msg.sender, 12);
    }

    // /*
    // Below are functions that are publicly available to view 
    // contract state.
    // */


    function contractURI() public view returns (string memory) {
        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, "contract.json"));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        if (exclusiveTokens[tokenId]){
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, exclusiveURI)): "";
        } else {
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    /*
    Below are internal functions that are not publicly available
    and do not alter contract state.
    */

    function _baseURI() internal view virtual override returns (string memory) {
        return BaseURI;
    }
}