// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./TokenStore.sol";

abstract contract TokenStoreWrapper is Context {
    using SafeERC20 for IERC20;

    IERC20 public share;
    ITokenStore public store;

    function deposit(uint256 _amount) public virtual {
        share.safeTransferFrom(_msgSender(), address(this), _amount);
        share.safeIncreaseAllowance(address(store), _amount);
        store.deposit(_msgSender(), _amount);
    }

    function withdraw(uint256 _amount) public virtual {
        store.withdraw(_msgSender(), _amount);
        share.safeTransfer(_msgSender(), _amount);
    }
}
