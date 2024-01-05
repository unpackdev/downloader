// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC721.sol";

interface IFomoNifty is IERC721 {
    using SafeMath for uint256;

    event Minted(
        uint256 tokenId,
        address beneficiary,
        string tokenUri,
        address minter
    );

    function creators(uint256 tokenId) external view returns (address);

    function primarySalePrice(uint256 tokenId) external view returns (uint256);

    function mint(address _beneficiary, string calldata _tokenUri) external;

    function burn(uint256 _tokenId) external;

    function exists(uint256 _tokenId) external;

    function isApproved(uint256 _tokenId, address _operator) external;
}
