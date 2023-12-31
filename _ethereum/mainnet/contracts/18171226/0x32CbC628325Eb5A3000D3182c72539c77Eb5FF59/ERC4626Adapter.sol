// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC4626.sol";
import "./Adapter.sol";

contract ERC4626Adapter is Adapter {
    function deposit(IERC4626 vault_) external payable {
        IERC20 _token = IERC20(vault_.asset());
        uint256 _amount = _token.balanceOf(address(this));
        _approveIfNeeded(_token, address(vault_), _amount);
        vault_.deposit(_amount, address(this));
    }

    function withdraw(IERC4626 vault_) external payable {
        vault_.withdraw(vault_.balanceOf(address(this)), address(this), address(this));
    }
}
