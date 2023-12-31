// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IWETH9.sol";
import "./CommonErrors.sol";

abstract contract WethHelper {
    using SafeERC20 for IERC20;

    /**
     * @notice Address of wrapped eth contract.
     */
    address public immutable weth;

    /**
     * @param weth_ Address of wrapped eth contract.
     */
    constructor(address weth_) {
        if (address(weth_) == address(0)) {
            revert ConfigurationAddressZero();
        }

        weth = weth_;
    }

    /**
     * @notice Wraps eth.
     * @param amount Amount of eth to wrap.
     */
    function wrapEth(uint256 amount) internal {
        IWETH9(weth).deposit{value: amount}();
    }

    /**
     * @notice Unwraps eth.
     * @param amount Amount of eth to unwrap.
     */
    function unwrapEth(uint256 amount) internal {
        IWETH9(weth).withdraw(amount);
    }

    receive() external payable {}
}
