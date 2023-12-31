// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./LidoCrvStakerBase.sol";
import "./console.sol";

contract LidoCrvStaker is LidoCrvStakerBase {
    receive() external payable {
        uint256 depositEthAmount = msg.value / 2;
        uint256 depositStEthAmount = msg.value - depositEthAmount;
        
        require(depositEthAmount > 0, "!depositEthAmount ");
        require(depositStEthAmount > 0, "!depositStEthAmount");

        ILido(ST_ETH).submit{value: depositStEthAmount}(
            0x0000000000000000000000000000000000000000
        );
        uint256 stEthAmount = IERC20(ST_ETH).balanceOf(address(this));
        IERC20(ST_ETH).approve(CRV, type(uint256).max);

        uint256 depositEthAmountCopy = depositEthAmount;
        ICurve(CRV).add_liquidity{value: depositEthAmount}(
            [depositEthAmountCopy, stEthAmount],
            0
        );
        address lpToken = ICurve(CRV).lp_token();

        IERC20(lpToken).transfer(
            msg.sender,
            IERC20(lpToken).balanceOf(address(this))
        );

        uint256 remainingStEth = IERC20(ST_ETH).balanceOf(address(this));
        uint256 remainingEth = address(this).balance;

        require(remainingStEth <= 1, "!remainingStEth");
        require(remainingEth == 0, "!remainingEth");

    }
}
