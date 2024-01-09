// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";
import "./IERC721.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Pork1984ChapterII is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable, ContextMixin, NativeMetaTransaction {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string baseURI_;
    address proxyRegistryAddress;
    address genesisPork1984Address;
    mapping(uint256 => uint256) genesisTokensToChapter2MintedTokens;

    constructor(address _proxyRegistryAddress, address _genesisPork1984Address) ERC721("Pork1984 Chapter II", "PORK1984-C2") {
        proxyRegistryAddress = _proxyRegistryAddress;
        genesisPork1984Address = _genesisPork1984Address;
        setBaseURI("https://api.pork1984.io/api/chapter2/");
        _tokenIdCounter.increment();  // start from 1 but not from 0
        _pause();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI_;
    }

    function setBaseURI(string memory baseURI) public onlyOwner
    {
        baseURI_ = baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getChapter2TokenIdForGenesisTokenId(uint256 genesisTokenId) public view returns(uint256) {
        return genesisTokensToChapter2MintedTokens[genesisTokenId];
    }

    function canMintForGenesisToken(uint256 tokenId) public view returns(bool) {
        return genesisTokensToChapter2MintedTokens[tokenId] == 0;
    }

    function canMintForGenesisTokens(uint256[] memory genesisTokenIds) public view returns(bool) {
        for (uint256 i = 0; i < genesisTokenIds.length; i++) {
            if (!canMintForGenesisToken(genesisTokenIds[i])) {
                return false;
            }
        }
        return true;
    }

    function mintForGenesisToken(uint256 genesisTokenId) public whenNotPaused {
        require(canMintForGenesisToken(genesisTokenId), "Cannot mint a Chapter 2 token for given genesis token because it is already used");
        
        IERC721 pork1984 = IERC721(genesisPork1984Address);
        require(pork1984.ownerOf(genesisTokenId) == msg.sender, "Cannot mint a Chapter 2 token for given genesis token because it is not yours");

        uint256 tokenId = _tokenIdCounter.current();
        genesisTokensToChapter2MintedTokens[genesisTokenId] = tokenId;
        _tokenIdCounter.increment();
        
        _safeMint(msg.sender, tokenId);
    }

    function mintForGenesisTokens(uint256[] memory genesisTokenIds) public whenNotPaused {
        for (uint256 i = 0; i < genesisTokenIds.length; i++) {
            mintForGenesisToken(genesisTokenIds[i]);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

}
