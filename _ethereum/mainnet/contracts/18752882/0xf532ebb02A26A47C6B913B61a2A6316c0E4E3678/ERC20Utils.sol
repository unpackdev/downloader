// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20.sol";
import "./SafeERC20.sol";

library ERC20Utils {
    using SafeERC20 for IERC20;

    function _approve(IERC20 _token, address _spender, uint256 _amount) internal {
        uint256 currentAllowance = _token.allowance(address(this), _spender);
        if (currentAllowance > 0) {
            _token.safeDecreaseAllowance(_spender, currentAllowance);
        }
        _token.safeIncreaseAllowance(_spender, _amount);
    }
}
