pragma solidity ^0.5.0;

import "./IWeth.sol";

contract LibWeth 
{
    function convertETHtoWeth(address wethAddr, uint256 amount) internal {
        IWeth weth = IWeth(wethAddr);
        weth.deposit.value(amount)();
    }

    function convertWethtoETH(address wethAddr, uint256 amount) internal {
        IWeth weth = IWeth(wethAddr);
        weth.withdraw(amount);
    }
}