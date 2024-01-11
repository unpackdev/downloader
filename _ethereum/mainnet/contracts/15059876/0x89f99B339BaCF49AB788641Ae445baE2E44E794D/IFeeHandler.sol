// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";

interface IFeeHandler {
    function transferFee(IERC20 _token, address _from, address _rewardAccruer, uint256 _fee) external;
}
