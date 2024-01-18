// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

library Token {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function deposit(
        address contractAddress,
        address from,
        uint256 _amount
    ) internal {
        IERC20Upgradeable(contractAddress).safeTransferFrom(
            from,
            address(this),
            _amount
        );
    }

    function withdrawal(
        address contractAddress,
        address to,
        uint256 _amount
    ) internal {
        IERC20Upgradeable(contractAddress).safeTransfer(to, _amount);
    }
}
