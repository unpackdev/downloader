// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./CountersUpgradeable.sol";

contract Cili is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;
    string private baseURI;

    function initialize() external initializer {
        __ERC721_init("Cili nft", "CILI");
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();
        baseURI = "https://ipfs.io/ipfs/Qmf13GYdstd215m8UPcfAyzjkD1TjdX2YukQncFSzTVTJv/";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        require(bytes(newBaseURI).length > 0, "New baseURI must not be empty");
        baseURI = newBaseURI;
    }

    function safeMint(address to) public {
        require(balanceOf(to) == 0, "Address already holds an NFT");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
}
