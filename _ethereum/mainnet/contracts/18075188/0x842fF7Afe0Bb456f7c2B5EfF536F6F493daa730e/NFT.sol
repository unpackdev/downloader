/**
 * https://biubiu.tools
 */
// /\\\\\\\\   /\\\\\\\\  /\\\    /\\\  /\\\\\\\\   /\\\\\\\\  /\\\    /\\\  /\\\\\\\\\\\\  /\\\\\\\\      /\\\\\\\\    /\\\          /\\\\\\\\\\
// \/\\\   \\\ \/_/\\\_/  \/\\\   \/\\\ \/\\\   \\\ \/_/\\\_/  \/\\\   \/\\\ \/___/\\\___/ /\\\_____/\\\  /\\\_____/\\\ \/\\\        /\\\_______/
//  \/\\\   \\\   \/\\\    \/\\\   \/\\\ \/\\\   \\\   \/\\\    \/\\\   \/\\\     \/\\\    \/\\\    \/\\\ \/\\\    \/\\\ \/\\\       \/\\\
//   \/\\\\\\\     \/\\\    \/\\\   \/\\\ \/\\\\\\\     \/\\\    \/\\\   \/\\\     \/\\\    \/\\\    \/\\\ \/\\\    \/\\\ \/\\\       \/\\\\\\\\\\
//    \/\\\   \\\\  \/\\\    \/\\\   \/\\\ \/\\\   \\\\  \/\\\    \/\\\   \/\\\     \/\\\    \/\\\    \/\\\ \/\\\    \/\\\ \/\\\       \/_______/\\\
//     \/\\\    \\\  \/\\\    \/\\\   \/\\\ \/\\\    \\\  \/\\\    \/\\\   \/\\\     \/\\\    \/\\\    \/\\\ \/\\\    \/\\\ \/\\\               \/\\\
//      \/\\\\\\\\\  /\\\\\\\\ \/_/\\\\\\\\  \/\\\\\\\\\  /\\\\\\\\ \/_/\\\\\\\\      \/\\\    \/_/\\\\\\\\\  \/_/\\\\\\\\\  \/\\\\\\\\\\ /\\\\\\\\\/
//       \/______/   \/______/   \/_______/   \/______/   \/______/   \/_______/       \/_/       \/_______/     \/_______/   \/________/ \/_______/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract SubscriptionProofNFT is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        _tokenIdCounter.increment(); // 初始化为 1
    }

    // uri appId|createdAt|duration  e.g. eth-tx-builder|1693829838|604800
    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
