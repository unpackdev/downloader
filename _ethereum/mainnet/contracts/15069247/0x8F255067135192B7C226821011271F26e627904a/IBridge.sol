//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IBridge {

    event NativeFundsTransferred(address receiver, uint toChainId, uint amount);
	
    event ERC20FundsTransferred(address receiver, uint toChainId, uint amount, address tokenAddress);

    function transferNative(uint amount, 
        address receiver, 
        uint64 toChainId, 
        bytes memory extraData) external payable;

    function transferERC20(
        uint64 toChainId,
        address tokenAddress,
        address receiver,
        uint256 amount,
        bytes memory extraData) external;

}