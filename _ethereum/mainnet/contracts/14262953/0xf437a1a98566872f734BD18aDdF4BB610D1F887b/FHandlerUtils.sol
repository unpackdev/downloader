// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "./SafeERC20.sol";
import "./Tokens.sol";

function _handleInputData(
    address _thisContractAddress,
    address _inToken,
    address _outToken,
    bytes calldata _data
)
    view
    returns (
        uint256 amountIn,
        address[] memory path,
        address relayer,
        uint256 fee,
        address[] memory feePath
    )
{
    // Load real initial balance, don't trust provided value
    amountIn = _balanceOf(_inToken, _thisContractAddress);

    // Decode extra data;
    (, relayer, fee, path, feePath) = abi.decode(
        _data,
        (address, address, uint256, address[], address[])
    );
}

function _balanceOf(address _token, address _account) view returns (uint256) {
    return
        NATIVE == _token
            ? _account.balance
            : IERC20(_token).balanceOf(_account);
}
