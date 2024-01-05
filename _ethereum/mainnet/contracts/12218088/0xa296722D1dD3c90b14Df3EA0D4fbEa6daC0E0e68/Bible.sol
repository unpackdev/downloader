// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";

import "./console.sol";

interface IPage {
    function getStartingIndex() external returns (uint256);
    function totalSupply() external returns (uint256);
} 

/**
 * @title Bible contract
 */
contract Bible is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    mapping(uint256 => bool) public blackList;

    uint256 public constant MAX_NFT_SUPPLY = 1024;
    uint256 public constant DEFAULT_TIME_LIMIT_FOR_ART_CREATION = (86400 * 42); //~42 days 
    uint256 public artDepositTimelimit;
    bool public bookComplete = false;
    address private _pagesAddress;

    event ArtSubmission(address _owner, uint256 indexed _pageIndex, string _ipfsAddress);
    event OverrideArt(uint256 indexed _pageIndex, string _ipfsAddress);
    event Blacklisted(uint256 indexed _pageIndex);
    event UnBlacklisted(uint256 indexed _pageIndex);

    constructor (string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function startCreationTimer() public {
        require(IPage(_pagesAddress).getStartingIndex() != 0, "Starting index must be set");
        artDepositTimelimit = SafeMath.add(block.timestamp, DEFAULT_TIME_LIMIT_FOR_ART_CREATION);
    }

    function addGracePeriod(uint256 additionalTime) onlyOwner public {
        artDepositTimelimit = SafeMath.add(artDepositTimelimit, additionalTime);
    }

    function setEmergencyArtDepositTimelimit(uint256 _artDepositTimelimit) onlyOwner public {
        artDepositTimelimit = _artDepositTimelimit;
    }

    function setEmergencyBookComplete(bool _bookComplete) onlyOwner public {
        bookComplete = _bookComplete;
    }

    /**
    * @dev Deposit art for given page tokenId
    */
    function createArt(uint256 tokenId, string memory ipfsAddress) public {
        require(IERC721(_pagesAddress).ownerOf(tokenId) == msg.sender, "Sender is not the owner");
        require(artDepositTimelimit != 0, "Art timer has not been started");
        require(artDepositTimelimit >= block.timestamp , "Create Art timer has ended");
        require(bookComplete == false, "Book is complete");
        IERC721(_pagesAddress).transferFrom(msg.sender, address(this), tokenId);

        IPage page = IPage(_pagesAddress);
        uint256 pageStartIndex = page.getStartingIndex();
        uint256 pageSupply = MAX_NFT_SUPPLY; 
        uint256 bibleIndex = (tokenId + pageStartIndex) % pageSupply;

        _safeMint(msg.sender, bibleIndex);
        _setTokenURI(bibleIndex, ipfsAddress);

        if ((totalSupply() == pageSupply) || block.timestamp >= artDepositTimelimit) {
            bookComplete = true;
        }

        emit ArtSubmission(msg.sender, bibleIndex, ipfsAddress);
    }

    function editArt(uint256 tokenId, string memory ipfsAddress) public {
        address owner = ownerOf(tokenId);

        require(isBlacklisted(tokenId) == true, "Token is blacklisted");
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        require(bookComplete == false, "Book is complete");
        require(_msgSender() == owner, "Editor is not the owner");
        _setTokenURI(tokenId, ipfsAddress);
    }

    function overrideTokenUri(uint256 tokenId, string memory ipfsAddress) onlyOwner public { 
        _setTokenURI(tokenId, ipfsAddress);
        emit OverrideArt(tokenId, ipfsAddress);
    }

    /**
     * @dev Emergency withdraw ether from this contract (Callable by owner)
    */
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * @dev Get the pages address
     */
    function pagesAddress() public view returns (address) {
        return _pagesAddress;
    }

    /**
     * @dev Permissioning not added because it is only callable once. It is set right after deployment and verified.
     */
    function setPagesAddress(address _newPagesAddress) public {
        require(_pagesAddress == address(0), "Already set");
        
        _pagesAddress = _newPagesAddress;
    }

    /**
     * @dev Add a page to the blacklist.
     */
    function blacklist(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        blackList[tokenId] = true;
        emit Blacklisted(tokenId);
    }
    
    /** 
     * @dev Remove a page from the blacklist.
     */
    function unblacklist(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        blackList[tokenId] = false;
        emit UnBlacklisted(tokenId);
    }
    
    /**
     *  @dev Return true if the page is blacklisted, false otherwise.
     */
    function isBlacklisted(uint256 tokenId) public view returns (bool) {
        return !blackList[tokenId];
    }

    /**
     * @dev Redeem a physical copy of the book
     */
    function redeem(uint256 tokenId) public {
        address owner = ownerOf(tokenId);

        require(bookComplete == true, "Book is not complete");
        require(_msgSender() == owner, "Redeemer is not the owner");

        _burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}