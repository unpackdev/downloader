// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Tokens.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

library GelatoTokenUtils {
    function transferToGelato(
        address _gelato,
        address _token,
        uint256 _amount
    ) internal {
        if (_amount == 0) return;

        if (_token == NATIVE_TOKEN) {
            (bool success, ) = _gelato.call{value: _amount}("");
            require(success, "transferGelato: Gelato ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_token), _gelato, _amount);
        }
    }

    function getBalance(address token, address user)
        internal
        view
        returns (uint256)
    {
        return
            token == NATIVE_TOKEN
                ? user.balance
                : IERC20(token).balanceOf(user);
    }
}
