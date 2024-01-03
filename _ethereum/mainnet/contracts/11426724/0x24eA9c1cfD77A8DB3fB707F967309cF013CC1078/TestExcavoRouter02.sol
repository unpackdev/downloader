pragma solidity >=0.6.6;

import "./ExcavoRouter.sol";

contract TestExcavoRouter is ExcavoRouter {
    constructor(address _factory, address _WETH, address _xCAVO) public ExcavoRouter(_factory, _WETH, _xCAVO) {}

    function testSwap(address pair, uint amount0Out, uint amount1Out, address to, bytes calldata data, uint k) external {
        IExcavoPair(pair).swap(amount0Out, amount1Out, to, data, k);
    }
}