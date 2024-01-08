// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./WrappedToken.sol";

contract ShuttleVault is IWrappedToken, Context, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public token;

    constructor(address _token) public {
        token = IERC20(_token);
    }

    function burn(uint256 _amount, bytes32 _to) public override {
        token.safeTransferFrom(_msgSender(), address(this), _amount);

        emit Burn(_msgSender(), _to, _amount);
    }

    function mint(address _account, uint256 _amount) public override onlyOwner {
        token.safeTransfer(_account, _amount);
    }
}
