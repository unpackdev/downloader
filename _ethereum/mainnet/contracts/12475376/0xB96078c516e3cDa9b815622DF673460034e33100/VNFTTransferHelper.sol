// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
import "./IERC721.sol";
import "./IVNFT.sol";

library VNFTTransferHelper {
    function doTransferIn(address underlying, address from, uint256 tokenId) internal {
        IERC721 token = IERC721(underlying);
        token.transferFrom(from, address(this), tokenId);
    }

    function doTransferOut(address underlying, address to, uint256 tokenId) internal {
        IERC721 token = IERC721(underlying);
        token.transferFrom(address(this), to, tokenId);
    }

    function doTransferIn(address underlying, address from, uint256 tokenId, uint256 units) internal {
        IVNFT token = IVNFT(underlying);
        token.safeTransferFrom(from, address(this), tokenId, units, "");
    } 

    function doTransferOut(address underlying, address to, uint256 tokenId, uint256 units) internal {
        IVNFT token = IVNFT(underlying);
        token.safeTransferFrom(address(this), to, tokenId, units, "");
    } 
}

