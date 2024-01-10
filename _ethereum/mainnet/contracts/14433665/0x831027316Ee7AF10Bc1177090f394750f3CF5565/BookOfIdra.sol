// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "ERC721.sol";
import "ERC721Enumerable.sol";
import "ERC721Burnable.sol";
import "Ownable.sol";
import "Counters.sol";

/**
 ██████   ██████  ██████      ██ ███████      ██████   ██████  ███    ██ ███████                                   
██       ██    ██ ██   ██     ██ ██          ██       ██    ██ ████   ██ ██                                        
██   ███ ██    ██ ██   ██     ██ ███████     ██   ███ ██    ██ ██ ██  ██ █████                                     
██    ██ ██    ██ ██   ██     ██      ██     ██    ██ ██    ██ ██  ██ ██ ██                                        
 ██████   ██████  ██████      ██ ███████      ██████   ██████  ██   ████ ███████ ██                                
                                                                                                                   
                                                                                                                   
 █████  ███    ██  ██████  ███████ ██      ███████      █████  ██████  ███████     ███    ██  ██████  ████████     
██   ██ ████   ██ ██       ██      ██      ██          ██   ██ ██   ██ ██          ████   ██ ██    ██    ██        
███████ ██ ██  ██ ██   ███ █████   ██      ███████     ███████ ██████  █████       ██ ██  ██ ██    ██    ██        
██   ██ ██  ██ ██ ██    ██ ██      ██           ██     ██   ██ ██   ██ ██          ██  ██ ██ ██    ██    ██        
██   ██ ██   ████  ██████  ███████ ███████ ███████     ██   ██ ██   ██ ███████     ██   ████  ██████     ██        
                                                                                                                   
                                                                                                                   
██     ██ ██   ██  █████  ████████     ████████ ██   ██ ███████ ██    ██     ███████ ███████ ███████ ███    ███    
██     ██ ██   ██ ██   ██    ██           ██    ██   ██ ██       ██  ██      ██      ██      ██      ████  ████    
██  █  ██ ███████ ███████    ██           ██    ███████ █████     ████       ███████ █████   █████   ██ ████ ██    
██ ███ ██ ██   ██ ██   ██    ██           ██    ██   ██ ██         ██             ██ ██      ██      ██  ██  ██    
 ███ ███  ██   ██ ██   ██    ██           ██    ██   ██ ███████    ██        ███████ ███████ ███████ ██      ██ ██ 
                                                                                                                   

 */

contract BookOfIdra is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    /// @dev Address for GiveWell charity
    address private giveWellAddress = 0x7cF2eBb5Ca55A8bd671A020F8BDbAF07f60F26C1;

    /// @dev A list of the original owners
    mapping (uint256 => address) originalOwners;

    /// @dev Probably nothing
    mapping (uint256 => address) fallenAngels;

    /// @dev Creator address - Elohim
    address private _elohimAddress;

    /// @dev Creator address - Adonai
    address private _adonaiAddress;
    
    /// @dev Starting URL for metadata (before reveal)
    string private _projectBaseURI = '';

    /// @dev Determines if minting is available
    bool public isMintingActive = false;

    /// @dev Never give up hope
    bool public isAllLost = false;

    /// @dev Determines if owners can change metadata
    bool public isMetadataLocked = false;

    /// @dev Percentage of wallet that goes to charity
    uint256 public constant CHARITY_PERC = 10;

    /// @dev Maximum total angels that can be created
    uint256 public maxAngels;

    /// @dev Maximum total giveaways that can be minted by creators
    uint256 public constant MAX_GIVEAWAYS = 100;

    /// @dev Maximum angels minted per transaction
    uint256 public constant MAX_MINT_QUANTITY = 10;
    
    uint256 public constant ANGEL_PRICE = 0.05 ether;

    event FallenAngelCreated(address indexed owner, uint256 tokenId);

    constructor(string memory baseURI, uint256 maxSupply, address elohim, address adonai) ERC721("BookOfIdra", "IDRA") {
        _projectBaseURI = baseURI;
        _elohimAddress = elohim;
        _adonaiAddress = adonai;
        maxAngels = maxSupply;
        _tokenIdCounter.increment(); // Start at 1
    }

    function mintAngel(uint256 count) public payable {
        require(count <= MAX_MINT_QUANTITY, "Cannot mint that many angels at once");
        require(msg.value > 0 && msg.value >= ANGEL_PRICE * count, "Not correct purchase amount");
        require(_tokenIdCounter.current() + count <= maxAngels, "Purchase would exceed supply");
        require(isMintingActive == true, "Minting is not active");
        
        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            originalOwners[tokenId] = msg.sender;
            _safeMint(msg.sender, tokenId);
            _tokenIdCounter.increment();
        }
    }

    function mintGiveaway(address to, uint256 count) public onlyOwner {
        require(_tokenIdCounter.current() + count <= maxAngels, "Purchase would exceed supply");
        require(_tokenIdCounter.current() + count <= MAX_GIVEAWAYS, "Maximum giveaways would be exceeded");
        
        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            originalOwners[tokenId] = to;
            _safeMint(to, tokenId);
            _tokenIdCounter.increment();
        }
    }

    function burn(uint256 tokenId) public override {
        fall(tokenId);
    }

    function fall(uint256 tokenId) public {
        require(isAllLost == true, "Not all is lost. Do not give up hope.");
        require(ownerOf(tokenId) == msg.sender, "This Angel is pure. And you are not.");
        fallenAngels[tokenId] = msg.sender;
        _burn(tokenId);
        emit FallenAngelCreated(msg.sender, tokenId);
    }

    function getOriginalOwner(uint256 tokenId) public view returns(address) {
	    return originalOwners[tokenId];
	}

    function getFallenAngel(uint256 tokenId) public view returns(address) {
	    return fallenAngels[tokenId];
	}

    function _baseURI() internal override view returns (string memory) {
        return _projectBaseURI;
    }

	function setBaseUri(string memory newUri) public onlyOwner {
        require(isMetadataLocked == false, "Metadata is locked");
        _projectBaseURI = newUri;
    }

    function lockMetadata() public onlyOwner {
        require(isMetadataLocked == false, "Metadata already locked");
        isMetadataLocked = true;
    }

    function setAllIsLost() public onlyOwner {
        isAllLost = true;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 remainder = 100 - CHARITY_PERC;
        payable(giveWellAddress).transfer((balance / 100) * CHARITY_PERC);
        payable(_elohimAddress).transfer((balance / 100) * (remainder / 2));
        payable(_adonaiAddress).transfer((balance / 100) * (remainder / 2));
        assert(address(this).balance == 0);
    }

    function toggleIsMintingActive() public onlyOwner {
        isMintingActive = !isMintingActive;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}