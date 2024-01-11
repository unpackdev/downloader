// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./PartLib.sol";
import "./MintERC721Lib.sol";
import "./SignatureLib.sol";

interface IERC721LazyMint is IERC721Upgradeable {
    event Minted(bytes32 indexed mintERC721Hash);

    function lazyMint(
        MintERC721Lib.MintERC721Data memory mintERC721Data,
        SignatureLib.SignatureData memory signatureData
    ) external;

    function isMinted(uint256 tokenId) external view returns (bool);
}
