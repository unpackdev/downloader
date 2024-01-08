// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./UniverseERC721.sol";
import "./Counters.sol";

contract UniverseERC721Core is UniverseERC721 {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    mapping(uint256 => address) public creatorOf;

    constructor(string memory _tokenName, string memory _tokenSymbol)
        UniverseERC721(_tokenName, _tokenSymbol)
    {}

    function batchMint(
        address receiver,
        string[] calldata tokenURIs,
        Fee[] memory fees
    ) external override returns (uint256[] memory) {
        require(tokenURIs.length <= 40, "Cannot mint more than 40 ERC721 tokens in a single call");

        uint256[] memory mintedTokenIds = new uint256[](tokenURIs.length);

        for (uint256 i = 0; i < tokenURIs.length; i++) {
            uint256 tokenId = mint(receiver, tokenURIs[i], fees);
            mintedTokenIds[i] = tokenId;
        }

        return mintedTokenIds;
    }

    function batchMintWithDifferentFees(
        address receiver,
        string[] calldata tokenURIs,
        Fee[][] memory fees
    ) external override returns (uint256[] memory) {
        require(tokenURIs.length <= 40, "Cannot mint more than 40 ERC721 tokens in a single call");
        require(tokenURIs.length == fees.length, "Wrong fee config");

        uint256[] memory mintedTokenIds = new uint256[](tokenURIs.length);

        for (uint256 i = 0; i < tokenURIs.length; i++) {
            uint256 tokenId = mint(receiver, tokenURIs[i], fees[i]);
            mintedTokenIds[i] = tokenId;
        }

        return mintedTokenIds;
    }

    function updateTokenURI(uint256 _tokenId, string memory _tokenURI)
        external
        override
        returns (string memory)
    {
        require(ownerOf(_tokenId) == msg.sender, "Owner: Caller is not the owner of the Token");
        _setTokenURI(_tokenId, _tokenURI);

        return _tokenURI;
    }

    function mint(
        address receiver,
        string memory tokenURI,
        Fee[] memory fees
    ) public override returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(receiver, newItemId);
        _setTokenURI(newItemId, tokenURI);
        _registerFees(newItemId, fees);
        creatorOf[newItemId] = msg.sender;

        emit UniverseERC721TokenMinted(newItemId, tokenURI, receiver, block.timestamp);
    }
}
