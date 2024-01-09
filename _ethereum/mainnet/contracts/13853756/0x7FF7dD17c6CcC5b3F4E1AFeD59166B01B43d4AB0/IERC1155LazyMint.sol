// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;
pragma abicoder v2;

import "./IERC1155Upgradeable.sol";
import "./PartLib.sol";
import "./ERC1155LazyMintLib.sol";

interface IERC1155LazyMint is IERC1155Upgradeable {
    event Supply(
        uint256 tokenId,
        uint256 value
    );
    event Creators(
        uint256 tokenId,
        PartLib.PartData[] creators
    );

    function mintAndTransfer(
        ERC1155LazyMintLib.ERC1155LazyMintData memory data,
        address to,
        uint256 _amount
    ) external;

    function transferFromOrMint(
        ERC1155LazyMintLib.ERC1155LazyMintData memory data,
        address from,
        address to,
        uint256 amount
    ) external;
}