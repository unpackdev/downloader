// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IFractonXRouter {

    function swapERC20ToERC721(address erc20Addr, uint256 amountERC20) external ;

    function swapERC721ToERC20(address erc721Addr, uint256 tokenId) external ;

    function isWhitelistUser(address user, address erc721Addr) external view returns(bool) ;

    function getAmountERC20(address erc20Addr) external view returns(uint256 amountERC20) ;

    function erc20TransferFeeRate(address erc20Addr) external view returns(uint256) ;
}
