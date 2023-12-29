pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IDysToken is IERC20 {
    function mint(address account) external;
}