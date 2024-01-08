// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract OpenCoordinates is
    ERC721,
    ERC721Enumerable,
    ReentrancyGuard,
    Pausable,
    Ownable
{
    uint16 private nextToken = 1;
    string public provenanceHash = "";
    string private baseURI = "";
    uint16 private constant MAX_SUPPLY = 10000;
    uint16 private constant OWNER_SUPPLY = 500;

    mapping(address => uint8) private _originalClaims; // Mint cap is 6 so uint8 ok

    // solhint-disable-next-line no-empty-blocks
    constructor() ERC721("Open Coordinates", "COORD") {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        if (bytes(provenanceHash).length == 0) {
            // Only set provenance once, no do-overs
            provenanceHash = provenance;
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory unpostfixed = ERC721.tokenURI(tokenId);
        if (bytes(unpostfixed).length == 0) {
            return "";
        }
        return string(abi.encodePacked(unpostfixed, ".json"));
    }

    function setNextToken(uint16 nextTokenId) public onlyOwner nonReentrant {
        // Emergency escape hatch if nextToken is corrupted somehow
        nextToken = nextTokenId;
    }

    function ownerClaim(uint16 tokenId)
        public
        onlyOwner
        whenNotPaused
        nonReentrant
    {
        // Allow owner to claim their reserved tokens... caller responsible for determining unclaimed IDs
        require(
            tokenId > 0 && tokenId >= (MAX_SUPPLY - OWNER_SUPPLY),
            "No available tokens"
        );
        _safeMint(_msgSender(), tokenId);
    }

    function claim() public whenNotPaused nonReentrant {
        require(
            nextToken > 0 && nextToken < (MAX_SUPPLY - OWNER_SUPPLY),
            "No available tokens"
        );
        uint8 claimed = _originalClaims[_msgSender()];
        require(claimed < 5, "Claim limit reached");
        _safeMint(_msgSender(), nextToken);
        nextToken = nextToken + 1;
        _originalClaims[_msgSender()] = claimed + 1;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
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
}
