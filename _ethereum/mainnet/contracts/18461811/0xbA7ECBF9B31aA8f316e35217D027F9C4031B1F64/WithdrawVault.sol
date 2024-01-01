// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./IERC20.sol";

contract WithdrawVault is Ownable {
    error NotERC20(address currency);
    error TransferFailed();

    event NativeCurrencyReceived(address indexed from, uint256 indexed amount);

    receive() external payable {}

    function depositNativeCurrency() external payable {
        emit NativeCurrencyReceived(msg.sender, msg.value);
    }

    function withdrawNativeCurrency(address receiver) external onlyOwner {
        (bool success, ) = receiver.call{
            value: address(this).balance,
            gas: 10000
        }("");
        if (!success) revert TransferFailed();
    }

    function withdrawERC20(
        address receiver,
        address currency
    ) external onlyOwner {
        if (currency.code.length == 0) revert NotERC20(currency);
        try IERC20(currency).balanceOf(address(this)) returns (
            uint256 balance
        ) {
            try IERC20(currency).transfer(receiver, balance) returns (
                bool success
            ) {
                if (!success) revert TransferFailed();
            } catch {
                revert NotERC20(currency);
            }
        } catch {
            revert NotERC20(currency);
        }
    }
}
