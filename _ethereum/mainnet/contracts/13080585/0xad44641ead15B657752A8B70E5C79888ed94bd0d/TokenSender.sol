// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./IERC20.sol";


contract TokenSender {
    function bulkSend(address token, address[] calldata addresses, uint256[] calldata amounts) external {
        require(addresses.length == amounts.length);
        uint256 len = addresses.length;
        for (uint256 i = 0; i < len; i++) {
            require(IERC20(token).transferFrom(msg.sender, addresses[i], amounts[i]));
        }
    }
}
