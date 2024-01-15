// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

interface ILazyMint {
    function mintAndTransfer(
        address from,
        address to,
        string memory _tokenURI,
        uint96 _royaltyFee
    ) external returns(uint256 _tokenId);
    
    function mintAndTransfer(
        address from,
        address to,
        string memory _tokenURI,
        uint96 _royaltyFee,
        uint256 supply,
        uint256 qty
    ) external returns(uint256 _tokenId);
}