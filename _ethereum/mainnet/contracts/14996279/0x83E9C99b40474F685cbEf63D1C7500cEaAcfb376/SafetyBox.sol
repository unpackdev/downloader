// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract SafetyBox is Ownable {
    using SafeERC20 for IERC20;

    function withdrawTo(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }
}
