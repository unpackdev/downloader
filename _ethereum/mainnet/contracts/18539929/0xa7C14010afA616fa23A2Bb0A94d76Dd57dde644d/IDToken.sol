// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDToken {

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function mint(address to, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

}
