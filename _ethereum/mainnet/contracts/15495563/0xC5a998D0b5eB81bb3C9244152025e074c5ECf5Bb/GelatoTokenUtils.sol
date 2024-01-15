// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./Tokens.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";

library GelatoTokenUtils {
    function transfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) return;
        if (_token == NATIVE_TOKEN) Address.sendValue(payable(_to), _amount);
        else SafeERC20.safeTransfer(IERC20(_token), _to, _amount);
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
