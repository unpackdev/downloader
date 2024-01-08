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
    IERC20 public storeToken;

    function deposit(uint256 _amount) public virtual {
        storeToken.safeTransferFrom(_msgSender(), address(this), _amount);
        storeToken.safeIncreaseAllowance(address(store), _amount);
        store.deposit(_msgSender(), _amount);
    }

    function withdraw(uint256 _amount) public virtual {
        store.withdraw(_msgSender(), _amount);
        storeToken.safeTransfer(_msgSender(), _amount);
    }
}
