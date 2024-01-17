// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IDepositController} from "IDepositController.sol";
import {IPortfolio} from "IPortfolio.sol";
import {Math} from "Math.sol";

contract DepositController is IDepositController {
    function maxDeposit(address) public view virtual returns (uint256) {
        return IPortfolio(msg.sender).maxSize() - IPortfolio(msg.sender).totalAssets();
    }

    function maxMint(address receiver) public view virtual returns (uint256) {
        return previewDeposit(maxDeposit(receiver));
    }

    function onDeposit(
        address,
        uint256 assets,
        address
    ) public view virtual returns (uint256, uint256) {
        return (previewDeposit(assets), 0);
    }

    function onMint(
        address,
        uint256 shares,
        address
    ) public view virtual returns (uint256, uint256) {
        return (previewMint(shares), 0);
    }

    function previewDeposit(uint256 assets) public view returns (uint256 shares) {
        return IPortfolio(msg.sender).convertToShares(assets);
    }

    function previewMint(uint256 shares) public view returns (uint256) {
        uint256 totalAssets = IPortfolio(msg.sender).totalAssets();
        uint256 totalSupply = IPortfolio(msg.sender).totalSupply();
        if (totalSupply == 0) {
            return shares;
        } else {
            return Math.ceilDiv((shares * totalAssets), totalSupply);
        }
    }
}
