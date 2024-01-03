// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./IERC20.sol";

interface IHope is IERC20 {
    function burn(address _account, uint256 _amount) external;
    function mint(address _account, uint256 _amount) external;
    function setLiquidityInitialized() external;
    function upgradeHopeNonTradable(uint256 _amount) external;
}