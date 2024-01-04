// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IRouter.sol";

interface IRulerFeeReceiver {
    event BuyBack(IERC20 _token, uint256 _amount);
    event Collected(IERC20 _token, uint256 _amount);

    // state vars
    function ruler() external returns (address);
    function xruler() external returns (address);
    function treasury() external returns (address);
    function feeRateToTreasury() external returns (uint256);

    // owner actions
    function buyBack(IERC20 _token, IRouter _router, address[] calldata _path, uint256 _maxSwapAmt, uint256 _amountOutMin) external;
    function collect(IERC20 _token, uint256 _amount) external;
    function setXruler(address _xruler) external;
    function setTreasury(address _treasury) external;
    function setFeeRateToTreasury(uint256 _feeRateToTreasury) external;
}