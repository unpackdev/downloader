// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FormaBase.sol";
import "./BurnMergeable.sol";

contract Project2 is FormaBase, BurnMergeable {
    mapping(uint256 => bytes32) public tokenIdToHash;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _baseURI,
        uint64 _pricePerToken,
        uint64 _maxTokens
    ) FormaBase(_tokenName, _tokenSymbol, _baseURI, _pricePerToken, _maxTokens) {
        minTokensMerged = 2;
        maxTokensMerged = 2;
    }

    function _mintToken(address _toAddress) internal override returns (uint256 _tokenId) {
        uint256 tokenId = freshTokensMinted;
        freshTokensMinted = freshTokensMinted + 1;

        bytes32 hash = keccak256(
            abi.encodePacked(tokenId, block.number, blockhash(block.number - 1), _toAddress)
        );

        _mint(_toAddress, tokenId);
        tokenIdToHash[tokenId] = hash;

        tokenIdToCount[tokenId] = 1;

        emit Mint(_toAddress, tokenId);

        if (msg.value > 0) {
            _splitFunds();
        }

        return tokenId;
    }

    function _mintMergedToken(uint256[] memory _tokenIds, address _toAddress)
        internal
        override
        returns (uint256)
    {
        uint256 tokenId = maxTokens + mergeTokensMinted;
        mergeTokensMinted = mergeTokensMinted + 1;

        bytes32 hash = keccak256(
            abi.encodePacked(tokenId, block.number, blockhash(block.number - 1), _toAddress)
        );

        _mint(_toAddress, tokenId);
        tokenIdToHash[tokenId] = hash;

        emit Merge(_tokenIds, _toAddress, tokenId);
        emit Mint(_toAddress, tokenId);

        return tokenId;
    }
}
