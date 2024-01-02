// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC721.sol";
import "./ERC721Structs.sol";

interface IOmniseaERC721 is IERC721 {
    function initialize(BasicCollectionParams memory _collectionParams, bytes32 _collectionId) external;
    function mint(address owner, uint256 _tokenId, string memory _tokenURI) external;
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function contractURI() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function circulatingSupply() external view returns (uint256);
}
