// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ERC2981.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./Ownable.sol";

error URIQueryForNonexistentTokenRFC();
error SaleIncomplete();
error CollectionNotRevealedYet();
error ContractPaused();
error ZeroMintFailed();
error MaxPerNFTAddrExceeded();
error SoldOut();
error InsufficientFunds();

contract ResearchFundingClub is ERC721A, ERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;

    struct CollectionData {
        uint256 minSupply;
        uint256 maxSupply;
        string baseURI;   
    }

    bool public paused = true;
    string public baseExtension = ".json";
    string public notRevealedURI;
    string public baseTokenURI;

    uint256 public MIN_SUPPLY = 0; // only used for multi-drop reveal check
    uint256 public MAX_SUPPLY = 25;
    
    uint256 public PRICE = 0.2 ether;
    uint256 public MAX_PER_MINT = 1;
    bool public revealed = false;

    uint256 public collectionID = 1;
    mapping(uint256 => CollectionData) public collections;

    // Wallets
    address public charityWallet = 0x7158d45648167222C89351CeBF618f413Bad08fb;
    address public devWallet = 0x81E3CBA331c2036044A62B54524a44D319D0E1ae;

    constructor(uint96 _royaltyFeesInBips, string memory _notRevealedURI) ERC721A("Research Funding Club", "RFC") {
        setRoyaltyInfo(msg.sender, _royaltyFeesInBips); // 2.5% = 2.5 * 100 = 250 
        notRevealedURI = _notRevealedURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentTokenRFC();

        if (!revealed && tokenId >= MIN_SUPPLY) {
            return notRevealedURI;
        }

        for (uint256 i=1; i <= collectionID; i++) {
            if (tokenId < collections[i].maxSupply) {
                tokenId = tokenId - collections[i].minSupply;
                return string(abi.encodePacked(collections[i].baseURI, tokenId.toString(), baseExtension));
            }
        }

        return '';
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return (
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }
  
    function mint(uint256 _mintAmount) external payable {
        if (msg.sender != owner()) {
            if (paused) revert ContractPaused();
            if (_mintAmount == 0) revert ZeroMintFailed();
            if (_mintAmount > MAX_PER_MINT) revert MaxPerNFTAddrExceeded();
            if (msg.value < PRICE * _mintAmount) revert InsufficientFunds();
        }

        uint256 supply = totalSupply();
        if (supply + _mintAmount > MAX_SUPPLY) revert SoldOut();

        _safeMint(msg.sender, _mintAmount);
    }

    function airDrop(uint256 _mintAmount, address destination) external onlyOwner  {
        uint256 supply = totalSupply();
        if (_mintAmount == 0) revert ZeroMintFailed();
        if (_mintAmount > MAX_PER_MINT) revert MaxPerNFTAddrExceeded();
        if (supply + _mintAmount > MAX_SUPPLY) revert SoldOut();
        _safeMint(destination, _mintAmount);
    }

    function tokensOfOwner(address _owner)
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

    function getCollectionInfo(uint256 _id) external view returns(CollectionData memory) {
        return collections[_id];
    }

    function reveal(string memory _newBaseURI) external onlyOwner {
        collections[collectionID] = CollectionData(MIN_SUPPLY, MAX_SUPPLY, _newBaseURI);
        revealed = true;
        collectionID++;
    }

    function newDrop(uint256 _newMaxSupply)
        external 
        onlyOwner
    {   
        if (totalSupply() != MAX_SUPPLY) revert SaleIncomplete(); 
        if (!revealed) revert CollectionNotRevealedYet();

        MIN_SUPPLY = MAX_SUPPLY;
        MAX_SUPPLY +=_newMaxSupply;
        revealed = false;
        paused = true; 
    }


    function setmaxMintAmount(uint256 _limit) external onlyOwner {
        MAX_PER_MINT = _limit;
    }

    function setmaxSupply(uint256 _limit) external onlyOwner {
        MAX_SUPPLY = _limit;
    }

    function setCost(uint256 _newCost) external onlyOwner {
        PRICE = _newCost;
    }

    function setNotRevealedURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedURI = _notRevealedURI;
    }
    
    function setBaseURI(uint256 _collectionID, string memory _baseTokenURI) external onlyOwner {
        collections[_collectionID].baseURI = _baseTokenURI;
    }

    function baseURI(uint256 _collectionID) external view returns(string memory) {
        return collections[_collectionID].baseURI;
    }
    
    function setBaseExtension(string memory _newBaseExtension)
        external
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw.");

        // charity
        (bool cw, ) = (charityWallet).call{
            value: (address(this).balance * 10) / 100
        }("");
        require(cw, "Charity Transfer failed.");

        // developer
        (bool df, ) = (devWallet).call{
            value: (address(this).balance * 5) / 100
        }("");
        require(df, "Developer Transfer failed.");

        // owner
        (bool success, ) = (msg.sender).call{value: address(this).balance}("");
        require(success, "Owner Transfer failed.");
    }
}