// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./LidoStakerBase.sol";
import "./console.sol";

contract LidoStaker is LidoStakerBase {
    receive() external payable {
        require(msg.value > 0, "msg.value == 0");

        ILido(ST_ETH).submit{value: msg.value}(
            0x0000000000000000000000000000000000000000
        );

        uint256 stEthAmount = IERC20(ST_ETH).balanceOf(address(this));
        IERC20(ST_ETH).transfer(msg.sender, stEthAmount);

        uint256 remainingStEth = IERC20(ST_ETH).balanceOf(address(this));
        uint256 remainingEth = address(this).balance;

        require(remainingStEth <= 1, "!remainingStEth");
        require(remainingEth == 0, "!remainingEth");
    }
}
