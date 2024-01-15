// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IERC721.sol";
import "./IERC998ERC721TopDown.sol";

interface IClusterPacker is IERC721 {
    function safeMint(address _to) external returns (uint256);

    function unpackBundle(uint256 _tokenId, address _receiver) external;
}
