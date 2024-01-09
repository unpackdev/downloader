pragma solidity 0.6.11;

import "./TestERC20Mock.sol";

contract USDCMock is TestERC20Mock {
    string public name = "USDC";
    string public symbol = "USDC";
    uint8 public decimals = 6;

}
