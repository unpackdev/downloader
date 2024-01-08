// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";


contract EtherWatch is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, AccessControl, Ownable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant TOKEN_URI_SETTER_ROLE = keccak256("TOKEN_URI_SETTER_ROLE");
    string public contractURI;
    mapping (uint256 => bool) public frozen;

    event PermanentURI(string _value, uint256 indexed _id);

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(TOKEN_URI_SETTER_ROLE, msg.sender);
        contractURI = "https://ether.watch/collection.json";
    }

    function _baseURI() internal pure override returns (string memory) {
        return "";
    }

    function safeMint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId);
    }

    function safeMintMultiple(address[] memory to, uint256[] memory tokenId) external onlyRole(MINTER_ROLE) {
        require(to.length == tokenId.length, "EtherWatch: Arrays not same length");
        for (uint256 i = 0; i < to.length; i++) {
            safeMint(to[i], tokenId[i]);
        }
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setTokenURI(uint256 tokenId, string memory newTokenURI) public onlyRole(TOKEN_URI_SETTER_ROLE) {
        require(!frozen[tokenId], "EtherWatch: Frozen");
        super._setTokenURI(tokenId, newTokenURI);
    }

    function setTokenURIMultiple(uint256[] memory tokenId, string[] memory newTokenURI) external onlyRole(TOKEN_URI_SETTER_ROLE) {
        require(tokenId.length == newTokenURI.length, "EtherWatch: Arrays not same length");
        for (uint256 i = 0; i < tokenId.length; i++) {
            setTokenURI(tokenId[i], newTokenURI[i]);
        }
    }

    function freezeTokenURI(uint256 tokenId) external {
        require(!frozen[tokenId], "EtherWatch: Already frozen");
        require(ownerOf(tokenId) == msg.sender, "EtherWatch: Not allowed");
        frozen[tokenId] = true;
        emit PermanentURI(tokenURI(tokenId), tokenId);
    }

    function setContractURI(string memory newContractURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = newContractURI;
    }
}
