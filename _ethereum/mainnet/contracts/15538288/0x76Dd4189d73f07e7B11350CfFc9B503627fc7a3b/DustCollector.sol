// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Governable.sol";
import "./IDustCollector.sol";

abstract contract DustCollector is IDustCollector, Governable {
    using SafeERC20 for IERC20;

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function sendDust(
        address _token,
        uint256 _amount,
        address _to
    ) external override onlyGovernance {
        if (_to == address(0)) revert ZeroAddress();
        if (_token == ETH_ADDRESS) {
            payable(_to).transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
        emit DustSent(_token, _amount, _to);
    }
}
