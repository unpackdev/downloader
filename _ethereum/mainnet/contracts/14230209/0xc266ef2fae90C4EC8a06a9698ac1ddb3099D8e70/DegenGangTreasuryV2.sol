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

    constructor() {
        projectWallet = 0x64786440426d6306B2966D3A6Eb96Be2261D123f;
        communityWallet = 0x083d6bcD88405c03f8A39dA4390894eE3B23FE30;
    }

    receive() external payable {}

    function withdrawErc20(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 totalBalance = token.balanceOf(address(this));
        uint256 restAmount = totalBalance;

        uint256 projectWalletAmount = totalBalance.mul(7000).div(10000);
        restAmount = restAmount.sub(projectWalletAmount);

        require(
            token.transfer(projectWallet, projectWalletAmount),
            "Withdraw Failed To Project Wallet."
        );

        require(
            token.transfer(communityWallet, restAmount),
            "Withdraw Failed To Community Wallet."
        );
    }

    function withdrawEth() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        uint256 restAmount = totalBalance;

        uint256 projectWalletAmount = totalBalance.mul(7000).div(10000);
        restAmount = restAmount.sub(projectWalletAmount);

        (bool withdrawProjectWallet, ) = projectWallet.call{
            value: projectWalletAmount
        }("");
        require(withdrawProjectWallet, "Withdraw Failed To Project Wallet.");

        (bool withdrawCommunityWallet, ) = communityWallet.call{
            value: restAmount
        }("");
        require(
            withdrawCommunityWallet,
            "Withdraw Failed To Community Wallet."
        );
    }
}