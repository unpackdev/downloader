pragma solidity ^0.6.6;

import "./IERC20.sol";

interface ILpToken is IERC20 {
    function mint(address, uint256) external;

    function burn(address, uint256) external;
}
