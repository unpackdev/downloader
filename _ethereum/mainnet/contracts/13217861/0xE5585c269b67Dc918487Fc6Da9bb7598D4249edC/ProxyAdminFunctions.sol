// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";

// solhint-disable-next-line private-vars-leading-underscore, func-visibility
function _withdrawETH(address _receiver, uint256 _amount) {
    Address.sendValue(payable(_receiver), _amount);
}

// solhint-disable-next-line private-vars-leading-underscore, func-visibility
function _withdrawUnlockedGEL(
    IERC20 _GEL, // solhint-disable-line func-param-name-mixedcase , var-name-mixedcase
    address _receiver,
    uint256 _gelBalance,
    uint256 _totalGelLocked
) {
    SafeERC20.safeTransfer(_GEL, _receiver, _gelBalance - _totalGelLocked);
}

// solhint-disable-next-line private-vars-leading-underscore, func-visibility
function _withdrawAllGEL(
    IERC20 _GEL, // solhint-disable-line func-param-name-mixedcase , var-name-mixedcase
    address _receiver,
    uint256 _gelBalance
) {
    SafeERC20.safeTransfer(_GEL, _receiver, _gelBalance);
}
