// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract FreeNFTMint is ERC1155, Ownable {
    constructor() ERC1155("") {}

    uint256 public TOTAL_MINTED = 0;
    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;
    string public name = "FreeNFTMint.App";
    mapping(uint256 => string) public _uris;
    mapping(uint256 => address) public _tokenOwners;

    // address mapping to tokenId  mapping(uint256 => string) private _uris;

    function getCurrentTokenId() public view returns (uint256) {
        return currentTokenId.current();
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return (_uris[tokenId]);
    }

    function contractURI() public view returns (string memory) {
        return "https://freenftmint.app/contractMeta.json";
    }

    function getTokenOwner(uint256 tokenId) public view returns (address) {
        return _tokenOwners[tokenId];
    }

    function setTokenURI(uint256 tokenId, string memory uri) public {
        require(
            msg.sender == _tokenOwners[tokenId],
            "The original address holder is only allowed to update the metadata"
        );
        _uris[tokenId] = uri;
    }

    function mint(
        address account,
        string memory uri,
        uint256 qty
    ) public {
        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _uris[newItemId] = uri;
        _mint(account, newItemId, qty, "");
        TOTAL_MINTED = TOTAL_MINTED + 1;
        _tokenOwners[newItemId] = account;
    }

    function mintBatch(
        address account,
        string[] memory uri,
        uint256[] memory amounts
    ) public {
        uint size = uri.length;
        uint256[] memory ids = new uint256[](size);

        for (uint256 i = 0; i < uri.length; i++) {
            currentTokenId.increment();
            uint256 newItemId = currentTokenId.current();
            _uris[newItemId] = uri[i];
            _tokenOwners[newItemId] = account;
            ids[i] = newItemId;
        }
        _mintBatch(account, ids, amounts, "");
        TOTAL_MINTED = TOTAL_MINTED + uri.length;
    }
}
