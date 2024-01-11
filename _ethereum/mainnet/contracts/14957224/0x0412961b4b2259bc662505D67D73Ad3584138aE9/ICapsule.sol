// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC721.sol";

interface ICapsule is IERC721 {
    function counter() external view returns (uint256);

    function mint(address account, string memory _uri) external;

    function burn(address owner, uint256 tokenId) external;

    function exists(uint256 tokenId) external view returns (bool);

    function isCollectionMinter(address _account) external view returns (bool);

    function setTokenURI(uint256 _tokenId, string memory _newTokenURI) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);
}
