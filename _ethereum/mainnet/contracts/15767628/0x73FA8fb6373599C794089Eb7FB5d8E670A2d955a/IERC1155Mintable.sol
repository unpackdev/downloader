// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC1155Mintable {
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        string memory tokenURI
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        string[] memory tokenURIs
    ) external;
}
