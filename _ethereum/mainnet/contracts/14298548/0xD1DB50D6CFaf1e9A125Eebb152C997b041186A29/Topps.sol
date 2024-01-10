// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC2981.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./Counters.sol";

contract Topps is ERC721, IERC2981, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    Counters.Counter private tokenCounter;

    string private baseURI;
    address private _recipient;

    uint256 public constant MAX_MINT = 1;

    constructor() ERC721("Topps Timeless", "TOPPS") {
        _recipient = owner();
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token."
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function claimItem(string memory tokenURI)
        external
        payable
        nonReentrant
        returns (uint256)
    {
        tokenCounter.increment();

        uint256 newItemId = tokenCounter.current();
        require(totalSupply() <= MAX_MINT, "Max mint has been met.");
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    function totalSupply() public view returns (uint256) {
        return tokenCounter.current();
    }

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * @dev See {IERC2981-NFT Royalty Standard}.
     */
    function _setRoyalties(address newRecipient) internal {
        require(
            newRecipient != address(0),
            "Royalties: new recipient is the zero address"
        );
        _recipient = newRecipient;
    }

    function setRoyalties(address newRecipient) external onlyOwner {
        _setRoyalties(newRecipient);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_recipient, (_salePrice * 750) / 10000);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no baseURI, return the tokenURI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI.
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
     * @dev See {ERC165-Interfaces}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
    }
}
