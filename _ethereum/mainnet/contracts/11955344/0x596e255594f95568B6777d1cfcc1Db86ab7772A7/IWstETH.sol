// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

import "./IERC20.sol";

interface IWstETH {
    /**
     * @return Returns amount of stETH for 1 wstETH
     */
    function stEthPerToken()
        external
        view
        returns (uint256);
}
