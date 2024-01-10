//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ContextMixin.sol";
import "./IMintableERC721.sol";

contract OperationSmile is ERC721, IMintableERC721, Ownable, ContextMixin {
    address internal _predicateProxy;
    uint256 internal _tokenIds;
    string internal _baseTokenURI;
    mapping(uint256 => string) internal _tokenUris;
    mapping(uint256 => uint256) internal _plantedAt;

    constructor(address predicateProxy)
        ERC721("ZeGarden - Operation Smile", "FLOWER")
    {
        _predicateProxy = predicateProxy;
    }

    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIds;
    }

    function exists(uint256 tokenId) external view override returns (bool) {
        return _exists(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return _tokenUris[tokenId];
    }

    function setTokenMetadata(uint256 tokenId, bytes memory data) internal virtual {
        (string memory uri, uint256 __plantedAt) = abi.decode(data, (string, uint256));

        _plantedAt[tokenId] = __plantedAt;
        _tokenUris[tokenId] = uri;
    }

    function mint(address user, uint256 tokenId) external override {
        require(_msgSender() == _predicateProxy, "Caller is not predicate proxy");

        _mint(user, tokenId);
        _tokenIds += 1;
    }

    function mint(address user, uint256 tokenId, bytes calldata metaData) external override {
        require(_msgSender() == _predicateProxy, "Caller is not predicate proxy");

        _mint(user, tokenId);
        _tokenIds += 1;

        setTokenMetadata(tokenId, metaData);
    }

    function plantedAt(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "Query for nonexistent token");

        return _plantedAt[tokenId];
    }

    function bloomed(uint256 tokenId) external view returns (bool) {
        require(_exists(tokenId), "Query for nonexistent token");

        return block.timestamp - _plantedAt[tokenId] >= 3 weeks;
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721, IERC721)
    {
        if (from != to) _plantedAt[tokenId] = 0;

        ERC721.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721, IERC721)
    {
        if (from != to) _plantedAt[tokenId] = 0;

        ERC721.safeTransferFrom(from, to, tokenId, data);
    }
}