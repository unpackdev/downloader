// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20Upgradeable.sol";

contract Airdropper {
    function disperseTokenSimple(
        IERC20Upgradeable token,
        address[] memory recipients,
        uint256[] memory values
    )  external {
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transferFrom(msg.sender, recipients[i], values[i]));
    }

    // function disperseToken(
    //     IERC20Upgradeable token,
    //     address[] memory recipients,
    //     uint256[] memory values
    // ) onlyRole(DEFAULT_ADMIN_ROLE) external {
    //     uint256 total = 0;
    //     for (uint256 i = 0; i < recipients.length; i++) 
    //         total += values[i];
    //     require(token.transferFrom(msg.sender, address(this), total));
    //     for (i = 0; i < recipients.length; i++)
    //         require(token.transfer(recipients[i], values[i]));
    // }
}
