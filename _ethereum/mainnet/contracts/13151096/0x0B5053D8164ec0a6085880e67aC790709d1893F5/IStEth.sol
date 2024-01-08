pragma solidity 0.8.2;

import "./ERC20.sol";

interface IStEth is IERC20 {
    function submit(address) external payable returns (uint256);
}