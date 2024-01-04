//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.6;

import "./UniswapV2Library.sol";
import "./IUniswapV2Router02.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Callee.sol";


import "./IERC20.sol";
import "./Ownable.sol";

/**
This contract serves as a proxy to manage flash swaps in Uniswap.
 */
contract FlashSwapProxy is IUniswapV2Callee, Ownable{

    fallback() external payable {}

    struct UniswapV2CallData {
        address token0;
        address token1;
        address tokenToReturn;
        address tokenRequested;
        uint amountRecived;
        address[] path;
        uint amountToReturn;
        address urn;
        uint ilk;
    }

    /**
    1) Uniswap      --TokenX-->    this            (This happens in UniswapV2Pair.swap)
    
    2) this         --TokenX-->    delegated call   --TokenY-->    this
    
    3) this         --TokenY-->    msg.sender      (msg.sender is UniswapV2Pair)

    @param sender msg.sender in the context of UniswapV2Pair.swap.
    @param amount0 amount0Out parameter in UniswapV2Pair.swap.
    @param amount1 amount1Out parameter in UniswapV2Pair.swap.
    @param _data data parameter in UniswapV2Pair.swap:
        It contains the following structure:
        address router02
            Address of the Uniswap Router02.
        uint256 minPrice
            Acceptable min price to be verified before returning the tokens to Uniswap.
            In case the price should be lower, then the transaction should be reverted.
        address target
            Address of the contract were should be delegated the transaction resolution.
        bytes dataForResolveUniswapV2Call
            Data to be passed as data parameter for the resolveUniswapV2Call function.

    Preconditions:
    1) amount0 and amount1 should have the same value than the amounts transfered
        by msg.sender (Uniswap Pair), so verify that the Pair contract where 
        sender calls the 'swap' method, is transferring the corresponding amounts.
    2) sender is msg.sender in the context of swap function in Pair contract.
    3) data is the data passed to the swap function without modifications.
     */
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata _data) external override {

        require(sender == owner() || sender == address(this), "FlashSwapProxy/uniswapV2Call: sender does not match owner.");

        UniswapV2CallData memory data;

        ( address router02, uint256 minPrice, address target, bytes memory dataForResolveUniswapV2Call ) = abi.decode(_data, (address, uint256, address, bytes));

        data.token0 = IUniswapV2Pair(msg.sender).token0();
        data.token1 = IUniswapV2Pair(msg.sender).token1();
        assert(msg.sender == IUniswapV2Factory(IUniswapV2Router02(router02).factory()).getPair(data.token0, data.token1));

        if (amount0 > 0){
            data.tokenToReturn = data.token1;
            data.tokenRequested = data.token0;
            data.amountRecived = amount0;
        } else {
            data.tokenToReturn = data.token0;
            data.tokenRequested = data.token1;
            data.amountRecived = amount1;
        }

        data.path = new address[](2);
        data.path[0] = amount0 == 0 ? data.token0 : data.token1;
        data.path[1] = amount0 == 0 ? data.token1 : data.token0;

        data.amountToReturn = IUniswapV2Router02(router02).getAmountsIn(data.amountRecived, data.path)[0];

        require(
            SafeMath.mul(data.amountRecived,1 ether) > SafeMath.mul(minPrice,data.amountToReturn) , 
            "FlashSwapProxy/uniswapV2Call: Actual price lower than min price."
            );

        (bool delegateSucced, bytes memory returnedData) = target.delegatecall(
            abi.encodeWithSignature(
                "resolveUniswapV2Call(address,address,address,uint256,uint256,bytes)",
                sender,
                data.tokenRequested,
                data.tokenToReturn,
                data.amountRecived,
                data.amountToReturn,
                dataForResolveUniswapV2Call
            )
        );

        if (delegateSucced == false) {
            // Reverts using the reason sent by the delegated call.
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }

        require(
            IERC20(data.tokenToReturn).balanceOf(address(this)) >= data.amountToReturn,
            "FlashSwapProxy/uniswapV2Call: Not enough amount to pay back the swap.");

        // Returning tokens to Pair.
        require(
            IERC20(data.tokenToReturn).transfer(msg.sender, data.amountToReturn),
            "FlashSwapProxy/uniswapV2Call: Fail transfer to pair."
        );

    }

    function execute(
        address _target, bytes memory _data
        ) 
        onlyOwner
        public 
        payable 
        returns (bytes32 response)
        {

        require(_target != address(0));

        // dynamic call passing ETH value, and where this would be msg.sender
        assembly {

            let succeeded := call(
                sub(gas(), 5000),  // we are passing the remaining gas except for 5000
                _target, // the target contract
                callvalue(), // ETH value sent to this function
                add(_data, 0x20), // pointer to data (the first 0x20 (32) bytes indicates de length)
                mload(_data), // size of data (the first 0x20 (32) bytes indicates de length)
                0, // pointer to store returned data
                32) // size of the memory where will be stored the data (defined 32 bytes fixed)
            response := mload(0)      // load call output
            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }

    }

}
