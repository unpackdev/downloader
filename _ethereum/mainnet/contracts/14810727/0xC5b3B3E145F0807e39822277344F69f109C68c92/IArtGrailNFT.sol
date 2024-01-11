// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMathUpgradeable.sol";
import "./IERC1155Upgradeable.sol";

interface IArtGrailNFT is IERC1155Upgradeable {
    using SafeMathUpgradeable for uint256;

    event Minted(
        uint256 tokenId,
        address beneficiary,
        string tokenUri,
        address minter
    );

    function getCreators(uint256 _id) external view returns (address[] memory);

    function primarySalePrice(uint256 tokenId) external view returns (uint256);

    function mint(address _beneficiary, string calldata _tokenUri) external;

    function burn(uint256 _tokenId) external;

    function exists(uint256 _tokenId) external;

    function isApproved(uint256 _tokenId, address _operator) external;
}
