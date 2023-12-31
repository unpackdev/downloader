// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Strings.sol";

import "./ISwappableRenderer.sol";

contract OffchainRenderer is Ownable, ISwappableRenderer {
    using Strings for uint256;

    string private baseURI = "https://d33649oufi5h0r.cloudfront.net/tokenURI/";

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function render(
        uint256 tokenId
    ) external view override returns (string memory) {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }
}
