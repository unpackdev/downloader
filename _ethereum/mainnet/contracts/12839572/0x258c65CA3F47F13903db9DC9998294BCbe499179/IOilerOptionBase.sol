// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./IERC20.sol";
import "./IERC20Permit.sol";
import "./IOilerCollateral.sol";

interface IOilerOptionBase is IERC20, IERC20Permit {
    function optionType() external view returns (string memory);

    function collateralInstance() external view returns (IOilerCollateral);

    function isActive() external view returns (bool active);

    function hasExpired() external view returns (bool);

    function hasBeenExercised() external view returns (bool);

    function put() external view returns (bool);

    function write(uint256 _amount) external;

    function write(uint256 _amount, address _onBehalfOf) external;
}
