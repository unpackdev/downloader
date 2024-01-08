// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC721.sol";

interface IMarketTradingNFT is IERC721 {
    //View
    function isApproved(uint256 _tokenId, address _operator) external view returns (bool);
    function setPrimarySalePrice(uint256 _tokenId, uint256 _salePrice) external;
    function postCreators(uint256 _tokenId) external view returns (address);
    function exists(uint256 _tokenId) external view returns (bool);
    function getNFTDetailByTokenId(uint256 _tokenId) external view returns (uint256, address, address, uint256, string memory);

    //external
    function mint(address _beneficiary, string calldata _tokenUri, address _designer) external returns (uint256);
    function burn(uint256 _tokenId) external;
    
}
