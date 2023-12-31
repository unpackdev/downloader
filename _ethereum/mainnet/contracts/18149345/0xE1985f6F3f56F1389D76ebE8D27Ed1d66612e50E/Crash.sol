//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.9;

import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./Counters.sol";

contract Crash is ERC721Burnable, Ownable {
    using Strings for uint256;

    constructor() ERC721("Crash Punks", "crash punks") {}

    function _baseURI() internal pure override returns (string memory) {
        return
            "ipfs://ipfs/QmYTX3u58v2Ero2drdtqhL6rPE5qnv51EJZ6WSu3LKqUBN/crashpunks-";
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function safeMintToken(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

}