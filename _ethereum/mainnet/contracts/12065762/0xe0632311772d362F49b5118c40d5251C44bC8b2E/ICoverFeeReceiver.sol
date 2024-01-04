// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IRouter.sol";

interface ICoverFeeReceiver {
    event BuyBack(IERC20 _token, uint256 _amount);
    event Collected(IERC20 _token, uint256 _amount);

    // state vars
    function cover() external returns (address);
    function forge() external returns (address);
    function treasury() external returns (address);
    function feeNumToTreasury() external returns (uint256);

    // owner actions
    function buyBack(IERC20 _token, IRouter _router, address[] calldata _path, uint256 _maxSwapAmt, uint256 _amountOutMin) external;
    function collect(IERC20 _token, uint256 _amount) external;
    function setForge(address _forge) external;
    function setTreasury(address _treasury) external;
    function setFeeNumToTreasury(uint256 _feeNumToTreasury) external;
}