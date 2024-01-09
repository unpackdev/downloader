// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.6;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract CongruentNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    address public auctionHouse;
    uint256 public currentTokenId;
    string private _baseURIExtended;
    mapping(uint256 => string) _tokenURIs;

    constructor() ERC721("CongruentNFT", "GaasNFT") {}

    modifier onlyAuctionHouse() {
        require(msg.sender == auctionHouse, "caller is not the auctionHouse");
        _;
    }

    event Minted(uint256 indexed tokenId, address receiver);
    event Burned(uint256 indexed tokenId);

    function setAuctionHouse(address _auctionHouse) external onlyOwner {
        auctionHouse = _auctionHouse;
    }

    function mint(address receiver)
    external
    onlyAuctionHouse
    nonReentrant
    returns (uint256 mintedTokenId)
    {
        mintedTokenId = currentTokenId;
        currentTokenId += 1;
        _mint(receiver, mintedTokenId);
        emit Minted(mintedTokenId, receiver);
    }

    function burn(uint256 tokenId) external onlyAuctionHouse nonReentrant {
        _burn(tokenId);
        emit Burned(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    // Sets base URI for all tokens, only able to be called by contract owner
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function setTokenURI(uint256[] calldata tokenIds, string[] calldata tokenURIs) external onlyOwner {
        require(tokenIds.length == tokenURIs.length, "invalid data");
        for (uint8 i; i < tokenIds.length; i++) {
            _tokenURIs[tokenIds[i]] = tokenURIs[i];
        }
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        if (bytes(_tokenURI).length != 0) {
            return _tokenURI;
        }

        string memory base = _baseURI();
        require(bytes(base).length != 0, "baseURI not set");
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }
}
