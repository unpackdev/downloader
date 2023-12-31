//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.9;

import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./Counters.sol";

contract Arties is ERC721Burnable, Ownable {
    using Strings for uint256;
    string baseURI =
        "ipfs://ipfs/QmWhLJ7D3xEGKUpDymxCWZRUj2VCZxaBC8Yfx6kZ5hLjBL/";

    constructor() ERC721("Arties", "Arties") {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newURI) external onlyOwner {
        baseURI = newURI;
    }

    function safeMintToken(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
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
}
