// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./SafeERC20.sol";

contract Airdrop is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    address public airdropToken;

    function initialize() public initializer {
        __Ownable_init();
    }

    function multiSend(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Array lengths mismatch");
        require(airdropToken != address(0), "Invalid Token Address");

        for (uint256 i = 0; i < recipients.length; i++) {
            IERC20(airdropToken).safeTransfer(recipients[i], amounts[i]);
        }
    }

    function changeTokenAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Invalid Token Address");
        airdropToken = newAddress;
    }
}