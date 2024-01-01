// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20.sol";
import "./Owned.sol";
import "./SafeTransferLib.sol";

contract RoyaltyHandler is Owned {
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    constructor() Owned(msg.sender) {}

    function sendETH(address payable to, uint256 amount) external onlyOwner {
        to.safeTransferETH(amount);
    }

    function sendERC20(address to, address erc20Address, uint256 amount) external onlyOwner {
        ERC20(erc20Address).safeTransfer(to, amount);
    }

    receive() external payable {}
}
