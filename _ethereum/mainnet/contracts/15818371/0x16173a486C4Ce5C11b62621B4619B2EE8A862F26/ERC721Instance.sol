// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721URIStorage.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./IFactory.sol";

contract ERC721Instance is ERC721Enumerable, ERC721Burnable, ERC721URIStorage, ReentrancyGuard {

    IFactory public factory;

    uint256 public totalIDs;

    mapping(uint256 => bool) mintIDUsed;

    event Mint(uint256 mintID, uint256 totalSupply, address sender);

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        factory = IFactory(_msgSender());
    }

    function mint(uint256 mintID, string calldata _tokenURI, uint256 deadline, bytes calldata signature) external nonReentrant {
        require(factory.signer() == ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(block.chainid, mintID, _msgSender(), address(this), _tokenURI, deadline))), signature), "Invalid signature");
        require(deadline >= block.timestamp, "Deadline passed");
        require(!mintIDUsed[mintID], "Mint ID already used");
        mintIDUsed[mintID] = true;
        _safeMint(_msgSender(), totalIDs);
        _setTokenURI(totalIDs, _tokenURI);
        emit Mint(mintID, totalIDs, _msgSender());
        totalIDs++;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || ERC721Enumerable.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        ERC721URIStorage._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }
}