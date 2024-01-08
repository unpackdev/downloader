// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FormaBase.sol";

abstract contract BurnMergeable is FormaBase {
    event Merge(uint256[] indexed _burned, address indexed _to, uint256 indexed _tokenId);

    uint8 public minTokensMerged = 2;
    uint8 public maxTokensMerged = 10;
    uint64 public mergeTokensMinted = 0;

    mapping(uint256 => uint32) public tokenIdToCount;
    mapping(uint256 => bool) public tokenIdToBurned;

    function merge(uint256[] memory _tokenIds) public returns (uint256 _tokenId) {
        require(
            salesState == SalesState.Active || salesState == SalesState.Maintenance,
            "Drop must be active or in maintenance"
        );
        require(_tokenIds.length >= minTokensMerged, "Merging less tokens than allowed");
        require(_tokenIds.length <= maxTokensMerged, "Merging more tokens than allowed");

        uint32 totalMergedCount = 0;
        for (uint16 i = 0; i < _tokenIds.length; i++) {
            _tokenId = _tokenIds[i];
            require(
                ERC721.ownerOf(_tokenId) == _msgSender(),
                "ERC721: Merging of token that is not own"
            );
            totalMergedCount += tokenIdToCount[_tokenId];
            _burn(_tokenId);
            tokenIdToBurned[_tokenId] = true;
        }

        uint256 mergedTokenId = _mintMergedToken(_tokenIds, msg.sender);
        tokenIdToCount[mergedTokenId] = totalMergedCount;

        return mergedTokenId;
    }

    function _mintMergedToken(uint256[] memory _tokenIds, address _toAddress)
        internal
        virtual
        returns (uint256 _tokenId);
}
