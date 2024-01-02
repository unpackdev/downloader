// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniswapV2Router.sol";

contract InuBurn is Ownable {
    
    IERC20 public WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); 
    IUniswapV2Router shibaBurnRouter = IUniswapV2Router(0x03f7724180AA6b939894B5Ca4314783B0b36b329);
    address shibaAddress = 0x243cACb4D5fF6814AD668C3e225246efA886AD5a;
    address burnAddress = 0xdEAD000000000000000042069420694206942069;

    event Burn(uint256 burned);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address owner) Ownable(owner) {
        WETH.approve(address(shibaBurnRouter), type(uint256).max);
    }


    function distribute() external {
        uint256 balance = WETH.balanceOf(address(this));
        uint256 wethToBurn = (balance/100) * 40;
        emit Burn(wethToBurn);
        if((balance == 0)) return;
        // Buy and burn Shina Inu
        address[] memory shinaPath = new address[](2);
        shinaPath[0] = shibaBurnRouter.WETH(); 
        shinaPath[1] = shibaAddress;
        shibaBurnRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(wethToBurn, 0, shinaPath, burnAddress, block.timestamp);
        //Transfer to Dev Wallet
        uint256 remainingBalance = balance - wethToBurn;
        WETH.transfer(owner(), remainingBalance);
    }

    // unstuck weth
    function rescueWeth() external onlyOwner() {
        uint256 wethBalance = WETH.balanceOf(address(this));
        WETH.transfer(msg.sender, wethBalance);
    }
    
    // unstuck eth
    function rescueEther() external onlyOwner() {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    
}