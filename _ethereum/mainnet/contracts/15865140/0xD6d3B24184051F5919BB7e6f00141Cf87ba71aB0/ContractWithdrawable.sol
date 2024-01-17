// SPDX-License-Identifier: MIT
// author   : k1merran.eth
// mail     : mark@criox.io
pragma solidity ^0.8.17;
import "./IERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract ContractWithdrawable is Ownable, ReentrancyGuard {
    // safety: withdraw ether
    function withdraw() public payable onlyOwner nonReentrant {
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(os);
    }

    // safety: withdraw ERC20
    function withdrawErc20(address erc20Address) public onlyOwner nonReentrant {
        IERC20 erc20 = IERC20(erc20Address);
        erc20.approve(address(this), erc20.balanceOf(address(this)));
        erc20.transferFrom(address(this), msg.sender, erc20.balanceOf(address(this)));
    }

    // safety: withdraw ERC721
    function withdrawErc721(address erc721Address, uint256 tokenId) public onlyOwner nonReentrant {
        IERC721 erc721 = IERC721(erc721Address);
        erc721.safeTransferFrom(address(this), msg.sender, tokenId);
    }
}