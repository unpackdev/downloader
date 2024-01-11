// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

/**
 * @title Rescuable
 * @dev Allows to withdraw external ERC20 tokens and Ether from smart contract
 */
contract Rescuable is Ownable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @notice Rescue ERC20 tokens locked up in this contract.
     * @param tokenContract ERC20 token contract address
     * @param to        Recipient address
     * @param amount    Amount to withdraw
     */
    function rescueERC20(
        IERC20Upgradeable tokenContract,
        address to,
        uint256 amount
    ) external onlyOwner {
        tokenContract.safeTransfer(to, amount);
    }

    function rescueEther(address payable to) external onlyOwner {
        to.transfer(address(this).balance);
    }

}