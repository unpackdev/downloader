// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./SafeERC20.sol";

contract BridgeMigrator {
    using SafeERC20 for IERC20;

    // Initialized
    uint8 private _initialized = 1;
    // Master Safe
    address private constant OWNER_ADDRESS =
        0xE075504E14bBB4d2aA6333DB5b8EFc1e8c2AE05B;
    //ETHER address
    address public constant ETHER_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function migrate(address payable recipient, IERC20 token) external {
        require(
            tx.origin == OWNER_ADDRESS,
            "Migrator: sender is not safe owner"
        );

        if (address(token) == ETHER_ADDRESS) {
            (bool sent, ) = recipient.call{value: address(this).balance}("");
            require(sent, "BridgeMigrator: ETH send failure");
        } else {
            token.safeTransfer(recipient, token.balanceOf(address(this)));
        }
    }
}
