// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

import "./IWETH.sol";
import "./IEthHandler.sol";

contract ETHHandler is IEthHandler {
    receive() external payable {}

    //Send WETH and then call withdraw
    function withdraw(address weth, uint256 amount) external override {
        IWETH(weth).withdraw(amount);
        (bool success, ) = msg.sender.call{ value: amount }(new bytes(0));
        require(success, "safeTransferETH: ETH transfer failed");
    }
}