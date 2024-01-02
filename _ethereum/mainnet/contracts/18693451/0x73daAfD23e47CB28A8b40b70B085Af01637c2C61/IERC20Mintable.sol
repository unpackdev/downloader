// SPDX-License_Identifier: MIT
pragma solidity 0.8.21;

interface IERC20Mintable {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}
