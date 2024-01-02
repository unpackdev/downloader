// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

contract MonsterHunting is Ownable, ERC721A {
    using Strings for uint256;

    uint256 public maxSupply = 5421;

    string private baseURI;

    constructor(
        string memory _uri
    ) ERC721A("Monster Hunting", "MH") Ownable(msg.sender) {
        baseURI = _uri;
    }

    function mint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= maxSupply, "Max supply exceeded");
        _mint(msg.sender, quantity);
    }

    function setBaseURI(string calldata data) external onlyOwner {
        baseURI = data;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
