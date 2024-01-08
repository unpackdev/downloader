// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./SafeERC20.sol";

contract BatchTransferFrom {
    using SafeERC20 for IERC20;

    function batchTransferFrom(IERC20 _token, address[] calldata _tos, uint[] calldata _amounts) external {
        uint len = _tos.length;
        require(len == _amounts.length, 'Invalid inputs length');
        for (uint i = 0; i < len; i++) {
            _token.safeTransferFrom(msg.sender, _tos[i], _amounts[i]);
        }
    }
}
