// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./CTokens.sol";

function _to18Decimals(
    address _token,
    uint256 _amount,
    string memory _revertMsg
) view returns (uint256) {
    if (_token == ETH) return _amount;

    try IERC20(_token).decimals() returns (uint8 _decimals) {
        return (_amount * (10**18)) / (10**uint256(_decimals));
    } catch {
        revert(_revertMsg);
    }
}