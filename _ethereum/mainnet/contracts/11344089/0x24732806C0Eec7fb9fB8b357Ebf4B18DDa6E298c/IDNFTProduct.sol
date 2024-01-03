// SPDX-License-Identifier: MIT
pragma solidity >0.6.0;
pragma experimental ABIEncoderV2;

import "./IERC721.sol";
import "./DNFTLibrary.sol";

interface IDNFTProduct is IERC721 {

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function mainAddr() external view returns (address);

    function pid() external view returns (uint16);

    function maxMintTime() external view returns (uint256);

    function maxTokenSize() external view returns (uint256);

    function costTokenAddr() external view returns (address);

    function cost() external view returns (uint256);

    function totalReturnRate() external view returns (uint32);

    function getDNFTPrice() external view returns (uint256);

    function mintTimeInterval() external view returns (uint256);

    function mintPerTimeValue() external view returns (uint256);

    function tokensOfOwner(address ownerAddr) external view returns (Lib.ProductTokenDetail[] memory);

    function tokenDetailOf(uint256 tid) external view returns (Lib.ProductTokenDetail memory);

    function tokenMintHistoryOf(uint256 tid) external view returns (Lib.ProductMintItem[] memory);

    function withdrawToken(address to, address token, uint256 value) external;

    function buy(address to) external returns (uint256);

    function mintBegin(address from, uint256 tokenId) external;

    function mintWithdraw(address from, uint256 tokenId) external returns (uint256, uint256);

    function redeem(address from, uint256 tokenId) external returns (uint256, uint256);

}