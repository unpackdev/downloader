pragma solidity ^0.7.4;

import "./IERC20.sol";

interface IWNXMToken is IERC20 {
    function wrap(uint256 _amount) external;

    function unwrap(uint256 _amount) external;
}
