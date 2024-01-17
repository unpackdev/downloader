// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./ERC1155.sol";

contract MockErc1155 is ERC1155 {
    // mapping(uint256 => string) public uris;

    constructor() ERC1155("") {}

    function mint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external {
        _mint(to, tokenId, amount, "");
    }

    // function batchMint(
    //     address to,
    //     uint256[] memory ids,
    //     uint256[] memory amounts,
    //     bytes memory data
    // ) external {
    //     _batchMint(to, ids, amounts, data);
    // }

    // function uri(uint256 id) public view override returns (string memory) {
    //     return uris[id];
    // }

    // function setUri(uint256 id, string memory _uri) external {
    //     uris[id] = _uri;
    // }
}
