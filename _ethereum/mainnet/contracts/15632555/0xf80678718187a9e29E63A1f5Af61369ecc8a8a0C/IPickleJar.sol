pragma solidity ^0.8.11;

import "./IERC20.sol";


interface IPickleJar is IERC20 {
    function getRatio() external view returns (uint256);
}
