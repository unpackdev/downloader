// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract JenkinsDrops is ERC1155, Ownable {

    string public baseURI;

    constructor() ERC1155("") {}

    function mint(address to, uint id, uint amount) external onlyOwner {
        _mint(to, id, amount, "");
    }

    // ADMIN FUNCTIONALITY

    /**
     * @dev Returns a URI for a given token ID's metadata
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    // METADATA FUNCTIONALITY

    /**
     * @dev Returns a URI for a given token ID's metadata
     */
    function uri(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

}
