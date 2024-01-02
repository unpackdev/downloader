// SPDX-License-Identifier: MIT
//
//      ___         ___         ___      ___         ___         ___
//     /\  \       /\  \       /\  \    /\  \       /\  \       /\__\
//    /::\  \     /::\  \     /::\  \   \:\  \     /::\  \     /:/  /
//   /:/\:\  \   /:/\:\  \   /:/\:\  \   \:\  \   /:/\:\  \   /:/  /
//  /::\~\:\  \ /:/  \:\  \ /::\~\:\  \  /::\  \ /::\~\:\  \ /:/  /
// /:/\:\ \:\__/:/__/ \:\__/:/\:\ \:\__\/:/\:\__/:/\:\ \:\__/:/__/
// \/__\:\/:/  \:\  \ /:/  \/_|::\/:/  /:/  \/__\/__\:\/:/  \:\  \
//      \::/  / \:\  /:/  /   |:|::/  /:/  /         \::/  / \:\  \
//       \/__/   \:\/:/  /    |:|\/__/\/__/          /:/  /   \:\  \
//                \::/  /     |:|  |                /:/  /     \:\__\
//                 \/__/       \|__|                \/__/       \/__/
//
pragma solidity 0.8.23;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

error ZeroAddress();
error ZeroBalance();

contract PortalPreSale is Ownable, ReentrancyGuard {
    address public constant PROCESSING_ADDRESS = 0x8603E8e5dF0C79C32f59785e89255a4518436485;
    address public withdrawAddress = 0xc238153C6a742dE9029927859868d106e44Ffe76;

    constructor(address owner) Ownable(owner) {}

    receive() external payable {}

    fallback() external payable {}

    function setWithdrawAddress(address newWithdrawAddress) external onlyOwner {
        if (newWithdrawAddress == address(0)) revert ZeroAddress();
        withdrawAddress = newWithdrawAddress;
    }

    function calculateDistribution(uint256 totalAmount) internal pure returns (uint256, uint256) {
        uint256 amountForProcessing = totalAmount / 100;
        uint256 amountForWithdrawal = totalAmount - amountForProcessing;
        return (amountForWithdrawal, amountForProcessing);
    }

    function withdrawETH() external onlyOwner nonReentrant {
        if (withdrawAddress == address(0)) revert ZeroAddress();
        uint256 balance = address(this).balance;
        if (balance == 0) revert ZeroBalance();
        (uint256 withdrawAmount, uint256 processingAmount) = calculateDistribution(balance);
        payable(PROCESSING_ADDRESS).transfer(processingAmount);
        payable(withdrawAddress).transfer(withdrawAmount);
    }

    function withdrawERC20(address tokenAddress) external onlyOwner nonReentrant {
        if (withdrawAddress == address(0)) revert ZeroAddress();
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        if (IERC20(tokenAddress).balanceOf(address(this)) == 0) revert ZeroBalance();
        (uint256 withdrawAmount, uint256 processingAmount) = calculateDistribution(balance);
        IERC20(tokenAddress).transfer(PROCESSING_ADDRESS, processingAmount);
        IERC20(tokenAddress).transfer(withdrawAddress, withdrawAmount);
    }
}
