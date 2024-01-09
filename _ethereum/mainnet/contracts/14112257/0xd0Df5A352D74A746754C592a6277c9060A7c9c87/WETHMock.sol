pragma solidity 0.6.11;

import "./TestERC20Mock.sol";

contract WETHMock is TestERC20Mock {
    string public name = "WETH";
    string public symbol = "WETH";
    uint8 public decimals = 18;

}
