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

contract Pork1984ChapterII is ERC721, Pausable, Ownable, ERC721Burnable, ContextMixin, NativeMetaTransaction {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string baseURI_;
    address proxyRegistryAddress;
    address genesisPork1984Address;
    mapping(uint256 => uint256) genesisTokensToChapter2MintedTokens;
    IERC721 genesisPork1984Contract;

    constructor(address _proxyRegistryAddress, address _genesisPork1984Address) ERC721("Pork1984 Chapter II", "PORK1984-C2") {
        proxyRegistryAddress = _proxyRegistryAddress;
        genesisPork1984Address = _genesisPork1984Address;
        genesisPork1984Contract = IERC721(_genesisPork1984Address);
        setBaseURI("https://api.pork1984.io/api/chapter2/");
        _pause();
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
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

    function _mintForGenesisToken(uint256 genesisTokenId, address to) internal {
        require(genesisPork1984Contract.ownerOf(genesisTokenId) == to, "Cannot mint a Chapter 2 token for given genesis token because it is not yours");

        _tokenIdCounter.increment();
        genesisTokensToChapter2MintedTokens[genesisTokenId] = _tokenIdCounter.current();
        _safeMint(msg.sender, _tokenIdCounter.current());
    }

    function giveForGenesisTokens(uint256[] memory genesisTokenIds, address to) public onlyOwner {
        for (uint256 i = 0; i < genesisTokenIds.length; i++) {
            _mintForGenesisToken(genesisTokenIds[i], to);
        }
    }

    function mintForGenesisToken(uint256 genesisTokenId) public whenNotPaused {
        require(canMintForGenesisToken(genesisTokenId), "Cannot mint a Chapter 2 token for given genesis token because it is already used");
        _mintForGenesisToken(genesisTokenId, msg.sender);
    }

    function mintForGenesisTokens(uint256[] memory genesisTokenIds) public whenNotPaused {
        for (uint256 i = 0; i < genesisTokenIds.length; i++) {
            mintForGenesisToken(genesisTokenIds[i]);
        }
    }

 /*
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
*/

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
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
