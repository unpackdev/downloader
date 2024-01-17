// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Address.sol";
import "./Proxied.sol";
import "./SafeERC20.sol";
import "./Tokens.sol";

contract FeeCollector is Proxied {
    using Address for address payable;
    using SafeERC20 for IERC20;

    function transfer(
        address _token,
        address _recipient,
        uint256 _amount
    ) external onlyProxyAdmin {
        _token == NATIVE_TOKEN
            ? payable(_recipient).sendValue(_amount)
            : IERC20(_token).safeTransfer(_recipient, _amount);
    }
}
