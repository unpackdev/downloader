// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract MePunk is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    bool reserved;
    address public auctionHouse;
    uint256 currentTokenId;
    string private _baseURIExtended;
    mapping(uint256 => string) _tokenURIs;

    constructor() ERC721("MePunk", "MPK") {}

    modifier onlyAuctionHouse() {
        require(msg.sender == auctionHouse, "caller is not the auctionHouse");
        _;
    }

    event Minted(uint256 indexed tokenId, address receiver);
    event Burned(uint256 indexed tokenId);

    function setAuctionHouse(address _auctionHouse) external onlyOwner {
        auctionHouse = _auctionHouse;
    }

    function reserveTokens(uint256 amount) external onlyOwner {
        require(!reserved, "can only reserve once");
        reserved = true;
        uint256 mintedTokenId;
        for (uint256 i=0; i<amount; i++){
            mintedTokenId = currentTokenId;
            currentTokenId += 1;
            _mint(msg.sender, mintedTokenId);
            emit Minted(mintedTokenId, msg.sender);
        }
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

    function setTokenURI(uint256 tokenId, string memory tokenURI_)
        external
        onlyOwner
    {
        _tokenURIs[tokenId] = tokenURI_;
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
