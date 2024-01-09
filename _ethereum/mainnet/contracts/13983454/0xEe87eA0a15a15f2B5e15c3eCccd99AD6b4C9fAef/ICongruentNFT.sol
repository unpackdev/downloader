// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.6;

import "./IERC721.sol";

interface ICongruentNFT is IERC721 {
    function currentTokenId() external returns (uint256);

    function mint(address receiver) external returns (uint256 tokenId);

    function burn(uint256 tokenId) external;
}
