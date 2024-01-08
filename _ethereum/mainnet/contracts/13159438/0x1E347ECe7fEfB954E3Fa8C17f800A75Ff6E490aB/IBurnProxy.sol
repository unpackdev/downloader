// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

interface IBurnProxy {
    function burnFrom(address from, uint256 amount) external;
}
