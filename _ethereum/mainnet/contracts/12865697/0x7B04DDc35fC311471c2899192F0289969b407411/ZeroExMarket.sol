// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "./IERC20.sol";

contract ZeroExMarket {

    address public constant ZEROEX = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;

    function _approve(address _token, uint256 _amount) internal {
        if (IERC20(_token).allowance(address(this), ZEROEX) < _amount) {
            IERC20(_token).approve(ZEROEX, ~uint256(0));
        }
    }

    function _checkCallResult(bool _success) internal pure {
        if (!_success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function swap(
        address token,
        uint256 amount,
        uint256 ethValue, 
        bytes calldata data
    ) external {
        if (token != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            _approve(token, amount);
        }
        (bool success, ) = ZEROEX.call{value:ethValue}(data);
        _checkCallResult(success);
    }
}