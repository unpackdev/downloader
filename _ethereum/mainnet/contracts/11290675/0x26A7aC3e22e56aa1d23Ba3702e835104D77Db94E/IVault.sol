// SPDX-License-Identifier: MIT
pragma solidity 0.5.17;

import "./IERC20.sol";

contract IVault is IERC20 {
    function token() external view returns (address);
    function claimInsurance() external; // NOTE: Only yDelegatedVault implements this
    function getPricePerFullShare() external view returns (uint);
    function deposit(uint) external;
    function withdraw(uint) external;
}
