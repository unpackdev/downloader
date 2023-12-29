// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeERC20.sol";

interface IGravitaDebtToken is IERC20 {
    function mintFromWhitelistedContract(uint256 _amount) external;

    function burnFromWhitelistedContract(uint256 _amount) external;
}
