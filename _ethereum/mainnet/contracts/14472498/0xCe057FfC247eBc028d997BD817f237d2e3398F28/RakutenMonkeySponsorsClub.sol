// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract RakutenMonkeySponsorsClub is
    ERC721Enumerable,
    Ownable,
    ReentrancyGuard
{
    using Strings for uint256;
    uint256 public currentTokenId;
    mapping(address => bool) public isAuctionHouse;
    string private _baseURIExtended;

    constructor() ERC721("Rakuten Monkey Sponsors Club", "RMSC") {}

    modifier onlyAuctionHouses() {
        require(
            isAuctionHouse[msg.sender],
            "caller is not one of the auctionHouses"
        );
        _;
    }

    event Minted(uint256 indexed tokenId, address receiver);
    event Burned(uint256 indexed tokenId);

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function setAuctionHouse(
        address[] calldata addresses,
        bool[] calldata states
    ) external onlyOwner {
        require(addresses.length == states.length, "array lenght mismatch");
        for (uint256 i = 0; i < addresses.length; i++) {
            isAuctionHouse[addresses[i]] = states[i];
        }
    }

    function mint(address receiver)
        external
        onlyAuctionHouses
        nonReentrant
        returns (uint256 mintedTokenId)
    {
        mintedTokenId = currentTokenId;
        currentTokenId += 1;
        _mint(receiver, mintedTokenId);
        emit Minted(mintedTokenId, receiver);
    }

    function burn(uint256 tokenId) external onlyAuctionHouses nonReentrant {
        _burn(tokenId);
        emit Burned(tokenId);
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
        string memory base = _baseURI();
        require(bytes(base).length != 0, "baseURI not set");
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }
}
