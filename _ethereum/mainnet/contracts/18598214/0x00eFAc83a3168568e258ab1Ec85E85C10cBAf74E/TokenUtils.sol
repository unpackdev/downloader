// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./Tokens.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./IERC20Permit.sol";
import "./SafeERC20.sol";

library TokenUtils {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Permit;

    modifier onlyERC20(address _token) {
        require(_token != NATIVE_TOKEN, "TokenUtils.onlyERC20");
        _;
    }

    function permit(
        address _token,
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal onlyERC20(_token) {
        IERC20Permit(_token).safePermit(
            _owner,
            _spender,
            _value,
            _deadline,
            _v,
            _r,
            _s
        );
    }

    function transfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) return;
        _token == NATIVE_TOKEN
            ? Address.sendValue(payable(_to), _amount)
            : IERC20(_token).safeTransfer(_to, _amount);
    }

    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal onlyERC20(_token) {
        if (_amount == 0) return;
        IERC20(_token).safeTransferFrom(_from, _to, _amount);
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
