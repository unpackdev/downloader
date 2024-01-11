// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./ERC721Upgradeable.sol";

interface IPaxWorldLandToken is IERC721Upgradeable {
    event PaxWorldLandCreated(address indexed owner, uint256 indexed tokenId);

    function baseTokenURI() external returns (string memory);

    function mintTokenId(address to, uint256 _tokenId) external returns (uint256);

    function mintTokenIdBatch(uint256[] calldata _tokenIds, address _toAddress) external;

    function mint(
        address to,
        int256 _x,
        int256 _y
    ) external returns (uint256);

    function pause() external;

    function unpause() external;

    function totalSupply() external view returns (uint256);

    function exists(uint256 _tokenId) external view returns (bool);

    function isValidTokenId(uint256 _tokenId) external view returns (bool);
}
