// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.5;

import "./IWETH9.sol";
import "./TransferHelper.sol";

contract WETHExtended {

    function withdraw(uint wad, address _beneficiary, IWETH9 WETH) public {

        WETH.withdraw(wad);
        TransferHelper.safeTransferETH(_beneficiary, wad);
    }

    receive() external payable {}
}