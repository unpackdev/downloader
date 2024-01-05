// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";

import "./console.sol";

/**
 * @title Pages contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract Pages is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

    uint256 public constant SALE_START_TIMESTAMP = 1618401600; // Wed Apr 14 2021 12:00:00 GMT+0000
    uint256 public constant REVEAL_TIMESTAMP = SALE_START_TIMESTAMP + (86400 * 14); //~14 days 
    uint256 public constant MAX_NFT_SUPPLY = 1024;
    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    uint256 public pricePerPage = 1000000000000000000; // 1 ETH
    string private _baseURIExtended;

    constructor (string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    /**
    * @dev get starting index
    */
    function getStartingIndex() public view returns (uint256) {
        return startingIndex;
    }
    /**
    * @dev Reserves Page
    */
    function reservePage(uint256 numberOfPages) public payable {
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended. No more $PAGES available");
        require(numberOfPages > 0, "numberOfPages cannot be 0");
        require(numberOfPages <= 20, "You may not buy more than 20 pages at once");
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started");
        require(SafeMath.add(totalSupply(), numberOfPages) <= MAX_NFT_SUPPLY, "Sale has already ended");
        require(SafeMath.mul(pricePerPage, numberOfPages) == msg.value, "Ether value sent is not correct");

        for (uint i = 0; i < numberOfPages; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }

        /**
        * Source of randomness. Theoretical miner withhold manipulation possible but should be sufficient in a pragmatic sense
        */
        if (startingIndexBlock == 0 && (totalSupply() == MAX_NFT_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }

    /**
     * @dev Finalize starting index
     */
    function finalizeStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_NFT_SUPPLY;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (SafeMath.sub(block.number, startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number-1)) % MAX_NFT_SUPPLY;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = SafeMath.add(startingIndex, 1);
        }

    }
    /**
     * @dev Used if not sold out
     */
    function emergencyMintAll() onlyOwner public {
        uint startIndex = totalSupply();
        for (uint i = startIndex; i < MAX_NFT_SUPPLY; i++) {
            uint mintIndex = i;
            _safeMint(msg.sender, mintIndex);
        }
        startingIndexBlock = block.number;
    }

    /**
     * @dev Withdraw ether from this contract (Callable by owner)
    */
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setPricePerPage(uint256 _pricePerPage) onlyOwner public {
        pricePerPage = _pricePerPage;
    }

    /*
    * Burn a page, used in the Bible contract when creatingArt
    */
    function burnPage(uint256 tokenId) public {
        _burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIExtended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}