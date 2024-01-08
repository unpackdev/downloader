// SPDX-License-Identifier: MIT

pragma solidity =0.8.3;

import "./Ownable.sol";
import "./SafeERC20.sol";

contract CharityWallet is Ownable {
    event Transfer(address token, address to, uint256 amount);

    using SafeERC20 for IERC20;

    function transfer(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (token == address(0)) {
            payable(to).transfer(amount);
        } else {
            IERC20(token).safeTransfer(to, amount);
        }

        emit Transfer(token, to, amount);
    }
}
