// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "./SafeERC20.sol";
import "./Tokens.sol";

library TokenUtils {
    using Address for address payable;
    using SafeERC20 for IERC20;

    function transfer(
        address _token,
        address _to,
        uint256 _amt
    ) internal {
        if (_token == ETH) payable(_to).sendValue(_amt);
        else IERC20(_token).safeTransfer(_to, _amt);
    }

    function balanceOf(address _token, address _account)
        internal
        view
        returns (uint256)
    {
        return
            ETH == _token
                ? _account.balance
                : IERC20(_token).balanceOf(_account);
    }
}
