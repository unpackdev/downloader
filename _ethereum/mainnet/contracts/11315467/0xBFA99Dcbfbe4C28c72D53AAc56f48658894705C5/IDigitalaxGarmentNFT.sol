// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC721.sol";

interface IDigitalaxGarmentNFT is IERC721 {
    function isApproved(uint256 _tokenId, address _operator) external view returns (bool);
    function setPrimarySalePrice(uint256 _tokenId, uint256 _salePrice) external;
    function garmentDesigners(uint256 _tokenId) external view returns (address);
}
