// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITokenURIRenderer.sol";
import "./Strings.sol";

contract TokenURIRenderer is ITokenURIRenderer {
    using Strings for uint256;

    function tokenURI(uint256 tokenId, string memory baseURI) public view virtual override returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
}
