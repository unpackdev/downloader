//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Address.sol";
import "./Math.sol";
import "./ERC721A.sol";

contract TOC is ERC721A, Ownable {
    using Address for address;

    uint256 private constant PRICE = 1e16;
    uint256 private constant MAX_SUPPLY = 33;

    /// @notice base uri for token metadata
    string private _baseURIExtended;

    /// @notice the last token id
    uint256 public lastTokenId;

    /// @notice moderators (mainly backend) to handle mint/burn
    mapping(address => bool) public moderators;

    modifier onlyModerator() {
        require(moderators[msg.sender], "TOC: NON_MODERATOR");
        _;
    }

    constructor() ERC721A("The Owners Club: First Edition 1/1 NFTs", "TOC") {
        moderators[msg.sender] = true;
    }

    function reserveNFTs() external onlyOwner {
        for (uint256 i; i < MAX_SUPPLY; i += 1) {
            _safeMint(msg.sender);
        }
    }

    /**
     * @dev set moderator address by owner (marketplace contracts)
     * @param moderator address of moderator
     * @param approved true to add, false to remove
     */
    function setModerator(address moderator, bool approved) external onlyOwner {
        require(moderator != address(0), "TOC: INVALID_MODERATOR");
        moderators[moderator] = approved;
    }

    /**
     * @dev called by moderator (backend) only to mint a new nft without payment
     * @param to address of mintee
     */
    function safeMint(address to) external onlyModerator {
        _safeMint(to);
    }

    /**
     * @dev called by moderator (backend) only to mint multiple new nfts without payment
     * @param to address of mintee
     * @param amount number of nfts to mint
     */
    function batchMint(address to, uint256 amount) external onlyModerator {
        for (uint256 i; i < amount; i += 1) {
            _safeMint(to);
        }
    }

    function _safeMint(address to) internal {
        lastTokenId += 1;
        _safeMint(to, lastTokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIExtended;
    }

    /**
     * @dev update base uri of nft contract
     * @param baseURI_ new base uri string
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }
}
