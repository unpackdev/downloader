// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract DegenGangTreasury is Ownable {
    using SafeMath for uint256;

    address public projectWallet;
    address public communityWallet;
    address public vonDoomWallet;

    constructor() {
        projectWallet = 0x64786440426d6306B2966D3A6Eb96Be2261D123f;
        communityWallet = 0x083d6bcD88405c03f8A39dA4390894eE3B23FE30;
        vonDoomWallet = 0x5F058DCcffB7862566aBe44F85d409823F5ce921;
    }

    receive() external payable {}

    function withdrawErc20(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 totalBalance = token.balanceOf(address(this));
        uint256 vonDoomWalletAmount = totalBalance;

        uint256 projectWalletAmount = totalBalance.mul(5000).div(10000);
        uint256 communityWalletAmount = totalBalance.mul(3000).div(10000);
        vonDoomWalletAmount = vonDoomWalletAmount.sub(projectWalletAmount).sub(communityWalletAmount);

        require(token.transfer(projectWallet, projectWalletAmount), "Withdraw Failed To Project Wallet.");

        require(token.transfer(communityWallet, communityWalletAmount), "Withdraw Failed To Community Wallet.");

        require(token.transfer(vonDoomWallet, vonDoomWalletAmount), "Withdraw Failed To VonDoom Wallet.");
    }

    function withdrawEth() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        uint256 vonDoomWalletAmount = totalBalance;

        uint256 projectWalletAmount = totalBalance.mul(5000).div(10000);
        uint256 communityWalletAmount = totalBalance.mul(3000).div(10000);
        vonDoomWalletAmount = vonDoomWalletAmount.sub(projectWalletAmount).sub(communityWalletAmount);

        (bool withdrawProjectWallet, ) = projectWallet.call{value: projectWalletAmount}("");
        require(withdrawProjectWallet, "Withdraw Failed To Project Wallet.");

        (bool withdrawCommunityWallet, ) = communityWallet.call{value: communityWalletAmount}("");
        require(withdrawCommunityWallet, "Withdraw Failed To Community Wallet.");

        (bool withdrawVonDoomWallet, ) = vonDoomWallet.call{value: vonDoomWalletAmount}("");
        require(withdrawVonDoomWallet, "Withdraw Failed To VonDoom Wallet.");
    }
}