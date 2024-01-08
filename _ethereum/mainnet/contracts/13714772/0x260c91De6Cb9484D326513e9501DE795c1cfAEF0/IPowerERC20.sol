pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IPowerERC20 is IERC20 {
    function mint(address account, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}