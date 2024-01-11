// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./ERC20Burnable.sol";

contract Bridge is Ownable {
    address public teamAccount;
    IERC721 public erc721Syl;
    ERC721Burnable public erc721Redeem;
    ERC20Burnable public erc20;

    constructor (
        address _teamAddr,
        address _erc721SylAddr,
        address _erc721RedeemAddr,
        address _erc20Addr
    ) {
        teamAccount = _teamAddr;
        erc721Syl = IERC721(_erc721SylAddr);
        erc721Redeem = ERC721Burnable(_erc721RedeemAddr);
        erc20 = ERC20Burnable(_erc20Addr);
    }

    function exchange(uint256 nftId) external {
        // Check Owner
        require(msg.sender == erc721Redeem.ownerOf(nftId), "Bridge: Invalid NFT Redeem Owner");

        // Burn Redeem NFT
        // Need Redeem NFT Burn approval from msg.sender
        erc721Redeem.burn(nftId);

        // Burn 7 SYL
        // Need approval from msg.sender
        erc20.burnFrom(msg.sender, 7 * 1e18);

        // Transfer SYL NFT
        // Need approval from redeem holder
        erc721Syl.transferFrom(teamAccount, msg.sender, nftId);
    }

    function setTeamAccount(address _teamAccountAddr) external onlyOwner {
        teamAccount = _teamAccountAddr;
    }

    function setERC721Syl(address _erc721SylAddr) external onlyOwner {
        erc721Syl = IERC721(_erc721SylAddr);
    }

    function setERC721Redeem(address _erc721RedeemAddr) external onlyOwner {
        erc721Redeem = ERC721Burnable(_erc721RedeemAddr);
    }

    function setERC20(address _erc20Addr) external onlyOwner {
        erc20 = ERC20Burnable(_erc20Addr);
    }
}