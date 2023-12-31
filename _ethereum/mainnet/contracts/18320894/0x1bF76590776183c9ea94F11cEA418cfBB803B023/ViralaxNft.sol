// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./IViralaxNft.sol";

contract ViralaxNft is ERC721Enumerable, IViralaxNft, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    // token id counter incrementing by 1
    Counters.Counter private _tokenIdTracker;
    mapping(uint256 => string) private _tokenURIs;
    address public viralexCity;

    constructor(string memory name, string memory symbol,
                address _viralexCity) public ERC721(name, symbol) {
        // increment tokenId
        _tokenIdTracker.increment();
        viralexCity = _viralexCity;
    }

    modifier viralexCityOnly() {
        require(viralexCity == msg.sender, "#viralexCityOnly:");
        _;
    }

    function changeViralexCity(address _viralaxCity) external onlyOwner{
        viralexCity = _viralaxCity;
    }

    function mint(address _to, string memory _metadata) override external viralexCityOnly {
        super._mint(_to, _tokenIdTracker.current());
        _setTokenURI(_tokenIdTracker.current(), _metadata);
        // increment tokenId
        _tokenIdTracker.increment();
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }
}
