// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IWETH.sol";

contract DustRefunder {
    using SafeERC20 for IERC20;

    function refundDust(address _rdnt, address _weth, address _refundAddress) internal {
        IERC20 rdnt = IERC20(_rdnt);
        IWETH weth = IWETH(_weth);

        uint256 dustWETH = weth.balanceOf(address(this));
        if (dustWETH > 0) {
            weth.transfer(_refundAddress, dustWETH);
        }
        uint256 dustRdnt = rdnt.balanceOf(address(this));
        if (dustRdnt > 0) {
            rdnt.safeTransfer(_refundAddress, dustRdnt);
        }
    }
}
