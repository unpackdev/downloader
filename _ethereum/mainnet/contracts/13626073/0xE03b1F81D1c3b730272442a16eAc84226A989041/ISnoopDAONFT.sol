// SPDX-License-Identifier: GPL-3.0
import "./IERC721.sol";
pragma solidity ^0.8.6;

interface ISnoopDAONFT is IERC721 {
    function mint(address receiver) external returns (uint256 tokenId);

    function burn(uint256 tokenId) external;
}
