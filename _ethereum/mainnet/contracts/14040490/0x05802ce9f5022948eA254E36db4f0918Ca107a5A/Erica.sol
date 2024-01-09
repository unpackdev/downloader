//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Mintable.sol";

contract Erica is ERC721, Mintable {
    string public baseURI;

    constructor(
        address _imx,
        string memory initialBaseURI
    ) ERC721("Erica Gift", "EGFT") Mintable(msg.sender, _imx) {
        setBaseURI(initialBaseURI);
    }

    function _mintFor(
        address user,
        uint256 id,
        bytes memory
    ) internal override {
        _safeMint(user, id);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }
}