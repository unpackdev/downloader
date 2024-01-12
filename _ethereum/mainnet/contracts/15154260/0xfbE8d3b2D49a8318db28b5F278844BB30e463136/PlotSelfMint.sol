// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Royalty.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./LibRoyaltiesV2.sol";
import "./ERC721TradableSimple.sol";
import "./ContentMixin.sol";

contract PlotSelfMint is ERC721TradableSimple, ERC721Royalty, Pausable {
    using SafeMath for uint256;
    using Strings for string;

    uint256 public mintPlotPrice = 0.05 ether;
    uint256 public constant MAX_PLOTS = 2082;
    uint256 private constant RESERVED_PLOTS = 91; // tokenId 1-91 is reserved for embassies, spawn, etc

    constructor(address _proxyRegistryAddress, address _royaltyReceiver) ERC721TradableSimple("Uplift World - Plot", "UPLIFT", _proxyRegistryAddress) {
        super._setDefaultRoyalty(_royaltyReceiver, 300);
        _pause();
    }

    function buyPlot(uint256 tokenId) public payable whenNotPaused {
        require(mintPlotPrice <= msg.value, 'LOW_ETHER');
        unchecked { require(tokenId > RESERVED_PLOTS && tokenId <= MAX_PLOTS, 'INVALID_ID'); }
        _safeMint(msg.sender, tokenId);
    }

    function mintPlotTo(address _to, uint256 tokenId) public onlyOwner {
        unchecked { require(tokenId > 0 && tokenId <= MAX_PLOTS, 'INVALID_ID'); }
        _safeMint(_to, tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://enter.theuplift.world/metadata/plots/json/";
    }

    function baseTokenURI() override public pure returns (string memory) {
        return "https://enter.theuplift.world/metadata/plots/json/";
    }

    // open sea needs this for royalties, description, etc - can be overridden via their UI
    function contractURI() public pure returns (string memory) {
        return "https://enter.theuplift.world/metadata/plots/opensea.contract.metadata.json";
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) virtual override(ERC721, ERC721TradableSimple) public view returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal virtual override(Context, ERC721TradableSimple) view returns (address sender) {
        return ContextMixin.msgSender();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Royalty) returns(bool) {
        // Rarible DAO Interface Support
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }

        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 _tokenId) virtual override(ERC721, ERC721TradableSimple) public pure returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        mintPlotPrice = newPrice;
    }

    function totalSupply() public pure returns (uint256) {
        return MAX_PLOTS;
    }
}